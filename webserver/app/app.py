# import the Flask class from the flask module
from flask import Flask, render_template, redirect, url_for, request, session, flash, send_file, after_this_request
from functools import wraps
from time import sleep
import requests
from mysql_utils import db_auth, db_update_info, db_update_passwd, db_info, db_get_client_cert
from ca_server_utils import ca_get_admin_info, ca_revoke_cert, ca_download_cert, ca_get_revoked_list, ca_check_certificate
import hashlib
import time
import os
import re
import logging
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address


# create the application object
app = Flask(__name__)

app.logger.setLevel(logging.INFO)
app.secret_key = "secret"


limiter = Limiter(get_remote_address, app=app, default_limits=["300 per day", "100 per hour"])

# disabling caching 
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0


def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs): 
        if 'uid' in session:
            return f(*args, **kwargs)
        else:
            app.logger.error("User tried to access %s without being logged in", f.__name__)
            return redirect(url_for('login'))
    return wrap

@app.route('/')
def default():
    if not session.get('uid'):
        return redirect(url_for('login'))
    else:
        return redirect(url_for('home'))

# Route for handling the login page logic
@app.route('/login', methods=['GET', 'POST'])
@limiter.limit("10 per minute")
def login():
    if request.method == 'POST':

        user_id = request.form['user_id']
        
        # user_id is 2 characters long and can't be modified at any point
        if len(user_id) != 2:
            resp = False
            # To prevent timing side channel attacks
            db_auth("invalid user_id", "dummy", app.logger)
        else:
            resp = db_auth(user_id, request.form['password'], app.logger)
        

        if resp != True:
            flash("incorrect user_id or password")
            app.logger.error("Failed login attempt for user %s", user_id)
            sleep(1) # to prevent brute force
            return redirect(url_for('login'))
        else:
            # get info from DB
            info = db_info(user_id, app.logger)
            
            if not info:
                flash("Error: Could not create session")
                return redirect(url_for('login'))
            
            app.logger.info("User %s logged in", user_id)
            
            session['firstname'] = info[0]
            session['lastname'] = info[1]
            session['email'] = info[2]
            
            session['uid'] = user_id
            
            app.logger.info("User %s logged in", user_id)
            
            return redirect(url_for('default'))
    
    # destroy session if user sends a GET request to /login
    session.pop('uid', None)
    session.pop('firstname', None)
    session.pop('lastname', None)
    session.pop('email', None)

    return render_template('login.html')

@app.route('/download_last_cert', methods=['GET'])
@login_required
def download_last_cert():
    cert = db_get_client_cert(session.get('uid'), app.logger)
    
    if cert is None:
        flash("Error: No valid certificate found")
        return redirect(url_for('home'))
    
    @after_this_request
    def remove_file(response):
        try:
            cert.close()
        except:
            app.logger.info("Error removing or closing downloaded certificate")
        return response

    app.logger.info("User %s downloaded last certificate", session.get('uid'))
    return send_file(cert.name, as_attachment=True, mimetype='application/x509-cert', download_name="certificate.crt")


#make sure user is logged in before accessing this page
@app.route('/home')
@login_required
def home():
    user = session.get('firstname') + " " + session.get('lastname')
    
    return render_template('home.html', user=user)  


@app.route('/download_crl', methods=['GET'])
@login_required
def download_crl():
    # download CRL from CA server
    revoked = ca_get_revoked_list(app.logger)
    
    if revoked is None:
        flash("Error: Could not download revoked list")
        app.logger.error("User %s could not download revoked list", session.get('uid'))
        return redirect(url_for('home'))
    else:
        @after_this_request
        def remove_file(response):
            try:
                revoked.close()
            except:
                app.logger.error("Error removing or closing downloaded CRL")
            return response
        
    app.logger.info("User %s downloaded CRL", session.get('uid'))
    return send_file(revoked.name, as_attachment=True, mimetype='application/pkix-crl', download_name="revoked_list.crl") 


    
@app.route('/logout')
@login_required
def logout():
    app.logger.info("User %s logged out", session.get('uid'))
    session.pop('uid', None)
    session.pop('firstname', None)
    session.pop('lastname', None)
    session.pop('email', None)
    return render_template('logout.html')  


@app.route('/modify_info', methods=['GET', 'POST'])
@login_required
def modify_info():
    user_info= {'firstname': session.get('firstname'), 'lastname': session.get('lastname'), 'email': session.get('email')}
    
    if request.method == 'POST':
        firstname = request.form['firstname']
        lastname = request.form['lastname']
        email = request.form['email']
        
        max_length = 50
        
        if not is_valid_input(firstname, max_length) or not is_valid_input(lastname, max_length):
            flash("Error: Invalid firstname or lastname")
            app.logger.error("User %s tried to update his info with invalid firstname or lastname", session.get('uid'))
            return redirect(url_for('modify_info'))
        elif not is_valid_email(email, max_length):
            flash("Error: Invalid email")
            app.logger.error("User %s tried to update his info with invalid email", session.get('uid'))
            return redirect(url_for('modify_info'))
        else:
            # update info in DB
            updated = db_update_info(firstname, lastname, email, session.get('uid'), app.logger)
                
        if updated is not None:
            app.logger.info("User %s updated his info", session.get('uid'))
            flash('User information successfully updated')
            
            #update data from DB
            session['firstname'] = updated[0]
            session['lastname'] = updated[1]
            session['email'] = updated[2]
            
                        
            sleep(1)

            return redirect(url_for('home'))
        else:
            app.logger.error("User %s could not update his info", session.get('uid'))
            flash('Error: Could not update your info')
    
    return render_template('modify_info.html', user_info=user_info)

@app.route("/modify_passwd", methods=['GET', 'POST'])
@login_required
def modify_passwd():
    form = request.form
    if request.method == 'POST':
        old_passwd = request.form['old_passwd']
        new_passwd = request.form['new_passwd']
        new_passwd_conf = request.form['new_passwd_conf']
        
        auth = db_auth(session.get('uid'), old_passwd, app.logger)

        if new_passwd != new_passwd_conf:
            flash('Passwords do not match')
            return redirect(url_for('modify_passwd'))
        
        # enfore password policy
        if len(new_passwd) < 8:
            flash("New passwords must be at least 8 characters long")
            return redirect(url_for('modify_passwd'))
        
        
        if auth:
            new_passwd_hash = hashlib.sha256(new_passwd.encode('utf-8')).hexdigest()
            
            resp = db_update_passwd(new_passwd_hash, session.get('uid'), app.logger)
            
            if resp:
                app.logger.info("User %s updated his password", session.get('uid'))
                session['passwd_changed'] = True
                sleep(1)
                return redirect(url_for('passwd_changed'))
            else:
                flash('Error: Could not update your password, please try again later')
                app.logger.error("User %s could not update his password, DB error", session.get('uid'))
                return redirect(url_for('home'))
        else:
            flash("Incorrect password")
            app.logger.error("User %s tried to update his password with incorrect old password", session.get('uid'))
            sleep(1) # prevent password brute force if hijacked session
            return redirect(url_for('modify_passwd'))

    return render_template('modify_passwd.html', form=form)


@app.route("/passwd_changed", methods=['GET'])
@login_required
def passwd_changed():
    if session.get('passwd_changed'):
        session.pop('passwd_changed', None)
        return render_template("passwd_changed.html")
    else:
        return redirect(url_for('home'))
    

@app.route("/new_certificate", methods=['GET'])
@login_required
def new_certificate():
    
    # add check to prevent user from requesting certificate too often
    t = session.get('last_cert_request')
    
    if t is not None:
        if time.time() - t < 60:
            flash("Error: You can only request a new certificate once every minute")
            app.logger.warning("User %s tried to request a new certificate again too soon", session.get('uid'))
            return redirect(url_for('home'))
    
    # revoke old certificates
    ca_revoke_cert(session.get('uid'), app.logger)
    # delete flash messages
    session.pop('_flashes', None)
    
    sleep(1)
            
    cert = ca_download_cert(session.get('uid'), session.get('lastname'), session.get('firstname'), session.get('email'), app.logger)
    
    if cert is not None:
        session['last_cert_request'] = time.time()
        app.logger.info("User %s successfully got new certificate", session.get('uid'))
        
        @after_this_request
        def remove_file(response):
            try:
                cert.close()
            except:
                app.logger.info("Error removing or closing downloaded certificate")
            return response
        
        return send_file(cert.name, as_attachment=True, mimetype='application/x-pkcs12', download_name="certificate.p12")
    
    else:
        flash("Error: Could not get new certificate")
        app.logger.error("User %s could not get new certificate", session.get('uid'))
        return redirect(url_for('home'))
   
   
@app.route("/revoke", methods=['GET'])
@login_required
def revoke_certificate():
    revoked = ca_revoke_cert(session.get('uid'), app.logger)
    if not revoked:
        return redirect(url_for('home'))
    
    sleep(1)
    return redirect(url_for('home'))
    
    
@app.route("/admin-interface", methods=['GET'])
def admin_interface():
    # CA Admin interface should only be accessible with admin certificate
    check = check_admin_certificate()
    
    if check:
        app.logger.info("CA admin accessed admin interface")
        resp = ca_get_admin_info(app.logger)
        if resp is None:
            flash("Error: Could not get CA state")
            return redirect(url_for('login'))
        
        return render_template('admin_interface.html', info=resp)
    else:
        app.logger.warning("User tried to access admin interface without being CA admin")
        return redirect(url_for('login'))


@app.route("/cert-login", methods=['GET'])
def cert_login():
    resp, client_uid = check_certificate()
    
    if resp:
        flash("Successfully logged in with certificate")
        app.logger.info("User %s logged in with certificate", client_uid)
        
        # add user info to session before redirecting to home        
        info = db_info(client_uid, app.logger)
        
        if not info:
            flash("Error: Could not create session")
            return redirect(url_for('login'))

        session['uid'] = client_uid
        session['firstname'] = info[0]
        session['lastname'] = info[1]
        session['email'] = info[2]
        
        return redirect(url_for('home'))
    else: 
        return redirect(url_for('login'))


def check_certificate():

    client_cert = request.environ.get('SSL_CLIENT_CERT') # PEM-encoded client certificate
    
    # check that SSL_CLIENT_VERIFY exists and is SUCCESS
    apache_verify = request.environ.get('SSL_CLIENT_VERIFY')
    
    if apache_verify != "SUCCESS":
        app.logger.error("Error: Apache could not verify client certificate, error code: %s", apache_verify)
        flash ("Error: Could not authenticate with certificate")
        return False, None
    
    # fetch client uid from certificate
    client_uid = request.environ.get('SSL_CLIENT_S_DN_UID')
    
    if client_uid is None:
        app.logger.error("Error: Certificate does not contain user id")
        flash("Error: Certificate does not contain user id")
        return False, None
    
    if client_uid == "ca-admin":
        app.logger.error("CA admine tried to authenticate through regular cert-login")
        flash("CA admin should authenticate through dedicated interface")
        return False, None
            

    #send request to ca server to check certificate not revoked
    resp = ca_check_certificate(client_cert,app.logger)
    
    if not resp:
        app.logger.error("User %s tried to authenticate with revoked certificate", client_uid)
        flash("Error: Certificate revoked")
        return False, None
    else:
        return True, client_uid
    
    
def check_admin_certificate():
    
    apache_verify = request.environ.get('SSL_CLIENT_VERIFY')
    
    client_uid = request.environ.get('SSL_CLIENT_S_DN_UID')
    
    
    if client_uid != "ca-admin" or apache_verify != "SUCCESS":
        if client_uid=="None":
            app.logger.error("Error: Certificate does not contain user id")
        else:
            app.logger.error("Error: User %s tried to access admin interface", client_uid)
        flash("Error: You are not the CA admin")
        return False
    else:
        app.logger.info("CA admin successfully authenticated with certificate")
        return True
    


def is_valid_input(value, max_length):
    # Check if the input value is not empty and doesn't contain special characters
    return bool(value) and re.match("^[a-zA-Z0-9 ]+$", value) and len(value) <= max_length


def is_valid_email(email, max_length):
    # Check if the email is valid
    return bool(email) and re.match("^[a-zA-Z0-9_.-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$", email) and len(email) <= max_length


if __name__ == '__main__':
    app.run(debug=False)
    
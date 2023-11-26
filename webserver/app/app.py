# import the Flask class from the flask module
from flask import Flask, render_template, redirect, url_for, request, session, flash, send_file, after_this_request
from functools import wraps
from time import sleep
import requests
from mysql_utils import db_auth, db_update_info, db_update_passwd, db_info
from ca_server_utils import ca_get_admin_info, ca_revoke_cert, ca_download_cert, ca_get_revoked_list
import hashlib
import time
import os

#use flask sessions to handle users (pop once logout or problem)
# session["uid"] = <uid fetched from DB for a given email/passwd

# par defaut page de login
# option pour rediriger vers login avec un certificat qui est une autre page
# and so on pour admin interface et tout le tralala. 

# regarder comment gérer les forms pour vérifier si forme des email est correcte / sanitization des inputs !

# regarder @login required

# TODO: differentiate between green and red flash messages
# TODO: add some css to make it look better
# TODO: setup HTTPS only
# TODO: add logger
# TODO: probably add all user info in session to avoid fetching it from DB everytime

DB_IP = "10.0.0.5"
CA_IP = "10.0.0.3"
DB_KEY = "BLA"


# create the application object
app = Flask(__name__)

# disabling caching 
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0

# TODO : set secret key to confidential value stored in vagrant as env variable (SECRET_KEY)
app.secret_key = "super secret key"


def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs): 
        #print("current session :", session.get('uid'))
        if 'uid' in session:
            return f(*args, **kwargs)
        else:
            return redirect(url_for('login'))
    return wrap

# use decorators to link the function to a url
@app.route('/')
def default():
    if not session.get('uid'):
        return redirect(url_for('login'))
    else:
        print(session.get('uid'))
        return redirect(url_for('home'))


# Route for handling the login page logic
@app.route('/login', methods=['GET', 'POST'])
def login():
    error_msg = None
    if request.method == 'POST':
        # TODO: check credentials on DB side
        user_id = request.form['user_id']
        resp = db_auth(user_id, request.form['password'])
        
        
        if resp != True:
            error_msg = "incorrect user_id or password"
            sleep(1) # to prevent brute force
        else:
            # get info from DB
            info = db_info(user_id)
            
            app.logger.info("User %s logged in", user_id)
            
            session['firstname'] = info[0]
            session['lastname'] = info[1]
            session['email'] = info[2]
            
            session['uid'] = user_id
            
            print("firstname, lastname, email", info[0], info[1], info[2])
            
            # TODO: fetch user id from DB
            #session['user_id'] = request.form['user_id']
            
            print("Succesfully logged in")
            return redirect(url_for('default'))
    
    # destroy session if user sends a GET request to /login
    session.pop('uid', None)

    return render_template('login.html', error=error_msg)



#make sure user is logged in before accessing this page
@app.route('/home')
@login_required
def home():
    print("session uid", session.get('uid'))
    
    user = session.get('firstname') + " " + session.get('lastname')
    
    return render_template('home.html', user=user)  


@app.route('/download_crl', methods=['GET'])
@login_required
def download_crl():
    # download CRL from CA server
    revoked = ca_get_revoked_list()
    
    if revoked is None:
        flash("Error: Could not download revoked list")
        return redirect(url_for('home'))
    else:
        @after_this_request
        def remove_file(response):
            try:
                os.remove(revoked.name)
            except Exception as error:
                app.logger.error("Error removing or closing downloaded CRL", error)
            return response

    return send_file(revoked.name, as_attachment=True, mimetype='application/pkix-crl', download_name="revoked_list.crl") 


    
@app.route('/logout')
@login_required
def logout():
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
        
        print("Updated info : ", firstname, lastname, email, session.get('uid'))
        
        updated = db_update_info(firstname, lastname, email, session.get('uid'))
        
        if updated is not None:
            flash('User information successfully updated')
            
            #update data from DB
            session['firstname'] = updated[0]
            session['lastname'] = updated[1]
            session['email'] = updated[2]
            
            sleep(1)

            return redirect(url_for('home'))
        else:
            flash('Error: Could not update your info')
    
    return render_template('modify_info.html', user_info=user_info)

#TODO: enforce password policy
@app.route("/modify_passwd", methods=['GET', 'POST'])
@login_required
def modify_passwd():
    message = None
    form = request.form
    if request.method == 'POST':
        old_passwd = request.form['old_passwd']
        new_passwd = request.form['new_passwd']
        new_passwd_conf = request.form['new_passwd_conf']
        
        # authentify old password
        auth = db_auth(session.get('uid'), old_passwd)

        if new_passwd != new_passwd_conf:
            flash('Passwords do not match')
            return redirect(url_for('modify_passwd'))
        
        if auth:
            new_passwd_hash = hashlib.sha256(new_passwd.encode('utf-8')).hexdigest()
            
            resp = db_update_passwd(new_passwd_hash, session.get('uid'))
            
            if resp:
                print("password updated")
                session['passwd_changed'] = True
                sleep(1)
                return redirect(url_for('passwd_changed'))
            else:
                flash('Error: Could not update your password, please try again later')
                return redirect(url_for('home'))
        else:
            flash("Incorrect password")
            return redirect(url_for('modify_passwd'))
            

    return render_template('modify_passwd.html', form=form, message=message)

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
            return redirect(url_for('home'))
    
    
    # revoke old certificates
    ca_revoke_cert(session.get('uid'), session.get('lastname'), session.get('firstname'), session.get('email'))
    
    sleep(1)
        
    #TODO: check format of download for pkcs12 + add a temporary password in flash message
    # flash("Certificate downloaded, your password is "+ "password")
    # flash ("Watchout if you reload the page, you won't see this message again and will have to issue a new certificate"")
    # redirecting user to a specific page to display download message and password
    
    cert = ca_download_cert(session.get('uid'), session.get('lastname'), session.get('firstname'), session.get('email'))
    
    if cert is not None:
        session['last_cert_request'] = time.time()
        #flash("Certificate downloaded")
        
        @after_this_request
        def remove_file(response):
            try:
                os.remove(cert.name)
            except Exception as error:
                app.logger.error("Error removing or closing downloaded certificate", error)
            return response
        
        return send_file(cert.name, as_attachment=True, mimetype='application/x-pkcs12', download_name="certificate.p12")
    # TODO: delete temporary file and possibly redirect to home ?
    # regarder @after_request qui return une page vers laquelle rediriger l'utilisateur
    
    else:
        flash("Error: Could not get new certificate")
        return redirect(url_for('home'))

   
   
@app.route("/revoke", methods=['GET'])
@login_required
def revoke_certificate():
    ca_revoke_cert(session.get('uid'), session.get('lastname'), session.get('firstname'), session.get('email'))
    
    flash("All your certificates have been revoked")
    return redirect(url_for('home'))
    
    
@app.route("/admin-interface", methods=['GET'])
def admin_interface():
    # CA Admin interface should only be accessible with admin certificate
    # TODO: check if user is admin
    resp = check_admin_certificate()
    
    #TODO: fetch administration info from CA server
    #resp = requests.get("http://"+CA_IP+"/admin")
    # resp = ca_get_admin_info()
    
    resp = {'nb_issued_certs': 10, 'nb_revoked_certs': 2, 'serial_nb': 5}
    return render_template('admin_interface.html', info=resp)

@app.route("/cert-login", methods=['GET'])
def cert_login():
    # TODO: check authentication with certificate
    resp = check_certificate()
    return "TODO"

        

    
#TODO: check certificate
def check_certificate():
    client_cert = request.environ.get('SSL_CLIENT_CERT')
    #TODO: check if certificate is valid along with CA server ? Check Apache config ! 
    return True

# TODO: check CA admin certificate
def check_admin_certificate():
    # TODO: query Admin CA certificate from DB ?
    # TODO: check certificate - cf Apache config
    return True
    


# start the server with the 'run()' method
if __name__ == '__main__':
    # TODO: add ssl_context='adhoc' to use HTTPS
    app.run(debug=True)
    
    
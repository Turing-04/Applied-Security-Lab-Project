# import the Flask class from the flask module
from flask import Flask, render_template, redirect, url_for, request, session, flash, send_file
from functools import wraps
from time import sleep
import requests
from mysql_utils import db_auth, db_update_info, db_update_passwd, db_info
from ca_server_utils import ca_get_admin_info, ca_revoke_cert, ca_download_cert
import hashlib

#use flask sessions to handle users (pop once logout or problem)
# session["uid"] = <uid fetched from DB for a given email/passwd

# par defaut page de login
# option pour rediriger vers login avec un certificat qui est une autre page
# and so on pour admin interface et tout le tralala. 

# regarder comment gérer les forms pour vérifier si forme des email est correcte / sanitization des inputs !

# regarder @login required

# TODO: check how flash messages should be displayed
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
            flash("You need to login first")
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
    
    #TODO: Fetch and show revocation list
    #revoked = ca_get_revoked_list()
    # revoked is in PEM format - need to convert it to a list of revoked certificates
    revoked = "revoked list"
    
    return render_template('home.html', user=user, revoked=revoked)  

    
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
            flash('Your info have been updated !') # TODO: check how to display flash message on POST or create an alert
            
            #update data from DB
            session['firstname'] = updated[0]
            session['lastname'] = updated[1]
            session['email'] = updated[2]
            
            sleep(1)

            return redirect(url_for('home'))
        else:
            flash('Could not update your info')
    
    return render_template('modify_info.html', user_info=user_info)

#TODO: enforce password policy
@app.route("/modify_passwd", methods=['GET', 'POST'])
@login_required
def modify_passwd():
    form = request.form
    if request.method == 'POST':
        old_passwd = request.form['old_passwd']
        new_passwd = request.form['new_passwd']
        new_passwd_conf = request.form['new_passwd_conf']
        
        # authentify old password
        auth = db_auth(session.get('uid'), old_passwd)

        if new_passwd != new_passwd_conf:
            flash('New password and confirmation password do not match')
        if auth and new_passwd == new_passwd_conf:
            new_passwd_hash = hashlib.sha256(new_passwd.encode('utf-8')).hexdigest()
            
            resp = db_update_passwd(new_passwd_hash, session.get('uid'))
            print("updated passwd", old_passwd, new_passwd)
            
            if resp:
                flash('Your password has been updated !')
                sleep(1)
                return redirect(url_for('home'))
            else:
                flash('Could not update your password')

    return render_template('modify_passwd.html', form=form)

@app.route("/new_certificate", methods=['GET'])
@login_required
def new_certificate():
    
    # TODO: revoke old certificates
    # for cert in getcertificatesfor(user_id)
    #resp = requests.post("http://"+CA_IP+"/revoke?user_id="+cert)
    
    #TODO: send request to CA to get new certificate
    #resp = requests.post("http://"+CA_IP+"/new")
    resp = {'status_code': 200, "bla": "bla"}
    
    if resp['status_code'] == 200:
        flash("Certificate should be downloaded automatically") # maybe add a link to download it manually 
        
        sleep(1)
        # TODO: download certificate from CA + get temporary password
        resp = ca_download_cert("bla")
        # passwd = resp['password']
        # cert = resp['cert']
        
        #cert = "certificate"
        
        #TODO: check format of download for pkcs12 + add a temporary password in flash message
        flash("Certificate downloaded, your password is "+ "password")
        
        # TODO: create a temporary file to store certificate
        cert = ca_download_cert("bla")
        
        return send_file(cert.name, as_attachment=True, mimetype='application/x-pkcs12', download_name="certificate.p12")
    # TODO: delete temporary file and possibly redirect to home ?
    # regarder @after_request qui return une page vers laquelle redirigier l'utilisateur
    
    else:
        flash("Could not get new certificate")
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

    
#TODO: check if it's a good idea to have a separate route for downloading certificate
    
@app.route("/revoke", methods=['GET'])
@login_required
def revoke_certificate():
    resp = ca_revoke_cert()
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
    
    
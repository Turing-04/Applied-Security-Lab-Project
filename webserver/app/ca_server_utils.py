import requests
import json
import tempfile
from flask import flash

import os


CA_IP = "10.0.0.3"


def ca_get_admin_info(logger):
    url = "https://"+CA_IP+"/ca-state"
    
    try:
        resp = requests.get(url, verify="/etc/ssl/certs/cacert.pem")
    except Exception as e:
        logger.error("Could not get admin info from CA server: {}".format(e))
        return None
        
    if resp.status_code == 200:
        print("CA state :", json.loads(resp.content))
        print("CA state type:", type(json.loads(resp.content)))
        return json.loads(resp.content)
    else:
        logger.error("Could not get admin info from CA server: {}".format(resp.content))
        return None
   
    
    
def ca_revoke_cert(user_id, logger):
    headers = {'Content-type': 'application/json'}
    
    payload= { 'uid': user_id}

    url = "https://"+CA_IP+"/revoke-certificate"
    
    try:
        response = requests.post(url, data=json.dumps(payload), headers=headers, verify="/etc/ssl/certs/cacert.pem")
    except Exception as e:
        logger.error("Could not revoke certificate: {}".format(e))
        return False
    
    if response.status_code == 200:
        return True
    elif response.status_code == 404 and "No valid ceritificate" in response.content.decode('utf-8'):
        flash("No valid certificate to revoke")
        logger.info("User {} tried to revoke a certificate but no valid certificate was found".format(user_id))
        return True
    else:
        logger.error("Could not revoke certificate: {}".format(response.content))
        return False
    
    
def ca_download_cert(user_id, lastname, firstname, email, logger):
    headers = {'Content-type': 'application/json'}
    
    
    payload= { 'uid': user_id, 'lastname': lastname, 'firstname': firstname, 'email': email}
    
    
    url = "https://"+CA_IP+"/request-certificate"
    
    try:
        response = requests.post(url, data=json.dumps(payload), headers=headers, verify="/etc/ssl/certs/cacert.pem")
    except Exception as e:
        logger.error("Could not download certificate: {}".format(e))
        return None
    
    if response.status_code == 200 and response.headers['Content-Type'] == 'application/x-pkcs12':
        # store certificate in temp file
        temp = tempfile.NamedTemporaryFile("w+b", delete=True)
        temp.write(response.content)
        temp.flush()
        return temp
    else:
        logger.error("Could not download certificate: {}".format(response.content))
        return None
    
def ca_get_revoked_list(logger):
    url = "https://"+CA_IP+"/crl"
    
    headers = {'Content-type': 'application/json'}
    
    try:
        response = requests.get(url, headers=headers, verify="/etc/ssl/certs/cacert.pem")
    except Exception as e:
        logger.error("Could not get revoked list: {}".format(e))
        return None
        
    if response.status_code == 200:
        temp = tempfile.NamedTemporaryFile("w+b", delete=True)
        temp.write(response.content)
        temp.flush()
        return temp
    else:
        return None
    
def ca_check_certificate(cert, logger):
    # check if certificate is revoked
    
    url = "https://"+CA_IP+"/is-certificate-valid"
    
    headers = {'Content-type': 'application/pkix-cert', 'Content-length': str(len(cert))}
    
    # send POST request with certificate
    try:
        response = requests.post(url, data=cert, headers=headers, verify="/etc/ssl/certs/cacert.pem")
    except Exception as e:
        logger.error("Could not check certificate: {}".format(e))
        return False
    
    if response.status_code == 200 and json.loads(response.content)['is_valid'] == True:
        logger.info("Certificate is not in revoked list")
        return True
    else:
        return False
    
    
    


  
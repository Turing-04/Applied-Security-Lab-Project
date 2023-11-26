import requests
import json
import tempfile

import os


CA_IP = "10.0.0.3"


def ca_get_admin_info():
    url = "https://"+CA_IP+"/ca-state"
    
    resp = requests.get(url, verify="/etc/ssl/certs/cacert.pem")
    
    if resp.status_code == 200:
        print("CA state :", json.loads(resp.content))
        print("CA state type:", type(json.loads(resp.content)))
        return json.loads(resp.content)
    else:
        print("Could not get CA state")
        return None
   
    
    
def ca_revoke_cert(user_id, lastname, firstname, email):
    headers = {'Content-type': 'application/json'}
    
    payload= { 'uid': user_id, 'lastname': lastname, 'firstname': firstname, 'email': email}

    url = "https://"+CA_IP+"/revoke-certificate"
    
    response = requests.post(url, data=json.dumps(payload), headers=headers, verify="/etc/ssl/certs/cacert.pem")
    if response.status_code == 200:
        return True
    else:
        return False
    
    
def ca_download_cert(user_id, lastname, firstname, email):
    headers = {'Content-type': 'application/json'}
    
    
    #TODO: check that email with a dot like "john.doe@gmail" accepted by regex on CA server
    payload= { 'uid': user_id, 'lastname': lastname, 'firstname': firstname, 'email': email}
    
    url = "https://"+CA_IP+"/request-certificate"
    
    response = requests.post(url, data=json.dumps(payload), headers=headers, verify="/etc/ssl/certs/cacert.pem")
    
    if response.status_code == 200 and response.headers['Content-Type'] == 'application/x-pkcs12':
        # store certificate in temp file
        
        temp = tempfile.NamedTemporaryFile("w+b", delete=True)
        temp.write(response.content)
        temp.flush()
        print("temp content", temp.read())
        #temp.close()
        return temp
    else:
        print("Could not download certificate")
        return None
    
def ca_get_revoked_list():
    url = "https://"+CA_IP+"/crl"
    
    headers = {'Content-type': 'application/json'}
    
    response = requests.get(url, headers=headers, verify="/etc/ssl/certs/cacert.pem")
    
    if response.status_code == 200:
        temp = tempfile.NamedTemporaryFile("w+b", delete=True)
        temp.write(response.content)
        temp.flush()
        return temp
    else:
        print("Could not get revoked list")
        return None
    
    
    


  
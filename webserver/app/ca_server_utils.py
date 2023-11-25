import requests
import json
import os


CA_IP = "10.0.0.3"


def ca_get_admin_info():
    url = "https://"+CA_IP+"/ca-state"
    try:
        r = requests.get(url)
        return r.json()
    except:
        print("Could not fetch admin info")
        return None
    
def ca_revoke_cert(username):
    headers = {'Content-type': 'application/json'}
    # TODO: Do I really need to send more than username ?
    user_info = {'username': username}
    url = "https://"+CA_IP+"/revoke-certificate"
    
    user_info_json = json.dumps(user_info)
    
    response = requests.post(url, data=user_info_json, headers=headers, verify=True)
    if response.status_code == 200:
        return True
    else:
        return False
    
    
def ca_download_cert(username):
    headers = {'Content-type': 'application/json'}
    
    user_info = {'username': username}
    
    dummy_info= { 'uid':'aa', 'firstname': "John", 'lastname': "Doe", 'email': 'john.doe@gmail.com'}
    
    # TODO: again, do I really need to send more than username ?
    url = "https://"+CA_IP+"/request-certificate"
    
    response = requests.post(url, data=json.dumps(dummy_info), headers=headers, verify=True)
    
    if response.status_code == 200 and response.content_type == "application/x-pkcs12":
        # store certificate in temp file
        import tempfile
        temp = tempfile.NamedTemporaryFile(delete=True)
        temp.write(response.content)
        #temp.close()
        return temp
    else:
        print("Could not download certificate")
        return None
    
def ca_get_revoked_list():
    url = "https://"+CA_IP+"/crl"
    try:
        r = requests.get(url)
        # crl is encoded in PEM format
        return r.content
    except:
        print("Could not fetch revoked list")
        return None

    
    
    
    
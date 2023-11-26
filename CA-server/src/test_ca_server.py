# from ca_server import *
from ca_server import make_csr, sign_csr, export_pkcs12, app
import pytest
import tempfile
import base64
import secrets
import string
import json
from cert_utils import build_subj_str, get_current_serial_nb
import os
import subprocess
from test_cert_utils import generate_random_string, decode_pkcs12

DUMMY_USER_INFO = {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
DUMMY_SUBJ_STR = "/C=CH/ST=Zurich/O=iMovies/CN=Lukas Bruegger/emailAddress=lb@imovies.ch"


# FLASK END-TO-END TESTS
# https://flask.palletsprojects.com/en/3.0.x/testing/

@pytest.fixture()
def app_fixture():
    app.config.update({
        "TESTING": True,
    })

    # other setup can go here

    return app

    # clean up / reset resources here


@pytest.fixture()
def client(app_fixture):
    return app.test_client()


@pytest.fixture()
def runner(app_fixture):
    return app.test_cli_runner()

def test_request_certificate(client):
    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(10)
    headers = {'Content-Type': 'application/json'}
    response = client.post("/request-certificate", data = json.dumps(user_info), headers=headers)

    assert response.status_code == 200
    assert response.content_type == "application/x-pkcs12"
    
    cert_file = tempfile.NamedTemporaryFile("w+b")
    cert_file.write(response.get_data())
    cert_file.flush()

    pkcs12_str = decode_pkcs12(cert_file.name)
    # print(pkcs12_str)

    for v in user_info.values():
        assert v in pkcs12_str

    assert "-----BEGIN CERTIFICATE-----" in pkcs12_str

    assert pkcs12_str.endswith("-----END PRIVATE KEY-----\n")

def test_revoke_non_existing_cert(client):
    uid_dict = {'uid': 'nonexistant'}

    headers = {'Content-Type': 'application/json'}
    response = client.post("/revoke-certificate", data = json.dumps(uid_dict), headers=headers)
    assert response.status_code == 404

def get_decoded_crl(client) -> str:
    response = client.get("/crl")
    assert response.status_code == 200
    crl_str = response.get_data(as_text=True)

    crl_file = tempfile.NamedTemporaryFile("w", encoding='utf-8')
    crl_file.write(crl_str)
    crl_file.flush()
    return decode_crl(crl_file.name)

def test_revoke_existing_cert(client):
    serial = get_current_serial_nb()

    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(20)
    headers = {'Content-Type': 'application/json'}

    user_info_json = json.dumps(user_info)
    response = client.post("/request-certificate", data = user_info_json, headers=headers)
    assert response.status_code == 200

    uid_dict = {'uid': user_info['uid']}
    response = client.post("/revoke-certificate", data = json.dumps(uid_dict), headers=headers)
    assert response.status_code == 200
    
    decoded_crl = get_decoded_crl(client)
    # Make sure that the serial number we just revoked is in the new crl
    assert f"Serial Number: {serial}" in decoded_crl

def decode_crl(crl_path: str) -> str:
    # openssl crl -in /etc/ssl/CA/crl.pem -text
    cmd = ["openssl", "crl"]
    cmd += ["-in", crl_path]
    cmd += ["-text"]

    out = subprocess.run(cmd, capture_output=True, text=True)
    return out.stdout

def test_get_crl(client):
    response = client.get("/crl")
    assert response.status_code == 200

    crl_str = response.get_data(as_text=True)
    
    assert crl_str.startswith("-----BEGIN X509 CRL-----")
    assert crl_str.endswith("-----END X509 CRL-----\n")

    crl_file = tempfile.NamedTemporaryFile("w", encoding='utf-8')
    crl_file.write(crl_str)
    crl_file.flush()

    decoded_crl = decode_crl(crl_file.name)
    assert "iMovies" in decoded_crl

def test_get_ca_state(client):
    state_1 = client.get("/ca-state")
    assert state_1.status_code == 200
    
    state_1_json = state_1.get_json()
    for key in ["current_serial_nb", "nb_certs_issued", "nb_certs_revoked"]:
        assert key in state_1_json.keys()
    
def test_ca_state_consistent(client):
    s1 = client.get("/ca-state").get_json()

    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(20)
    headers = {'Content-Type': 'application/json'}

    user_info_json = json.dumps(user_info)
    client.post("/request-certificate", data = user_info_json, headers=headers)

    s2 = client.get("/ca-state").get_json()
    # check state after requesting new certificate
    assert s2['current_serial_nb'] != s1['current_serial_nb']
    assert s2['nb_certs_issued'] - s1['nb_certs_issued'] == 1
    assert s2['nb_certs_revoked'] == s1['nb_certs_revoked']

    uid_dict = {'uid': user_info['uid']}
    client.post("/revoke-certificate", data = json.dumps(uid_dict), headers=headers)
    
    s3 = client.get("/ca-state").get_json()

    # check state after revoking certificate
    assert s3['current_serial_nb'] == s2['current_serial_nb']
    assert s3['nb_certs_issued'] == s2['nb_certs_issued']
    assert s3['nb_certs_revoked'] - s2['nb_certs_revoked'] == 1

    # print(s3, s2)
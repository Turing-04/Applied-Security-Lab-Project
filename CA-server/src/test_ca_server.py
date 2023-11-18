# from ca_server import *
from ca_server import make_csr, sign_csr, export_pkcs12, app
import pytest
import tempfile
import base64
import secrets
import string
import json
from cert_utils import build_subj_str
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
    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = "NEFirstname"
    user_info['lastname'] = "NELastname"

    headers = {'Content-Type': 'application/json'}
    response = client.post("/revoke-certificate", data = json.dumps(user_info), headers=headers)
    assert response.status_code == 404

def test_revoke_existing_cert(client):
    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(20)
    headers = {'Content-Type': 'application/json'}

    user_info_json = json.dumps(user_info)
    response = client.post("/request-certificate", data = user_info_json, headers=headers)
    assert response.status_code == 200

    response = client.post("/revoke-certificate", data = user_info_json, headers=headers)
    assert response.status_code == 200
    print(response.get_data())
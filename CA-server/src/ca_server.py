import subprocess
from flask import Flask, request
import re
import tempfile
from typing import Dict
import os

app = Flask(__name__)

OPENSSL_CMD = "openssl"
OPENSSL_KEY_PARAMS = "rsa:2048"

CERT_ORG_NAME = "iMovies"

def sign_csr(csr_path: str):
    """
    #  Now we are ready to sign certificates. Given a certificate signing request
    # (e.g., key.csr), the following command will generate a certificate signed
    # by Alice's CA:
    sudo openssl ca -in key.csr -config /etc/ssl/openssl.cnf
    The certificate is then saved in /etc/ssl/CA/newcerts/ as
    <serial-number>.pem.
    """
    assert os.path.exists(csr_path), csr_path

    assert False, "TODO"

def build_subj_str(user_info: Dict[str, str]) -> str:
    out = f"/C=CH/ST=Zurich/O={CERT_ORG_NAME}"

    firstname = user_info["firstname"]
    lastname = user_info["lastname"]
    assert firstname.isalpha(), firstname
    assert lastname.isalpha(), lastname
    out += f"/CN={firstname} {lastname}"

    email_regex = r"\w+@\w+\.\w+"
    email = user_info["email"]
    assert bool(re.match(email_regex, email)), email
    out += f"/emailAddress={email}/"
    
    return out

def make_csr(user_info: Dict[str, str], tmp_csr_path: str, tmp_priv_key_path: str) -> None:
    """
    openssl req -new \
        -newkey rsa:2048 -nodes -keyout tmp.key \
        -out tmp.csr \
        -subj "/C=CH/ST=Zurich/O=iMovies/CN=Lukas Bruegger/emailAddress=lb@imovies.ch/"
    """
    assert os.path.exists(tmp_csr_path) and os.path.exists(tmp_priv_key_path)
    cmd = [OPENSSL_CMD]
    cmd += ["req", "-new"]
    cmd += ["-newkey", OPENSSL_KEY_PARAMS, "-nodes", "-keyout", tmp_priv_key_path]
    cmd += ["-out", tmp_csr_path]
    subj_str = build_subj_str(user_info)
    cmd += ["-subj", subj_str]
    subprocess.run(cmd, check=True) 

@app.post("/request-certificate")
def request_certificate():
    """
    This endpoint allows the web server to request a signed certificate for 
    a user. The body of the request is a JSON object containing the user info,
    e.g.: 
    {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
    
    The CA server generates a fresh key pair for the user, generates and signs
    a corresponding certificate and responds with the signed certificate + the 
    private key in PKCS#12 format.

    The steps will roughly be:
    openssl req -new \
        -newkey rsa:2048 -nodes -keyout tmp.key \
        -out tmp.csr \
        -subj "/C=CH/O=iMovies/CN=Lukas Bruegger/emailAddress=lb@imovies.ch/"

    sudo openssl ca -in tmp.csr -config /etc/ssl/openssl.cnf
    TODO figure out how to not use interactive mode
    TODO make setuid script to make the signature as root

    openssl pkcs12 -export -out cert.p12 -inkey tmp.key\
         -in tmp.crt

    The cert.p12 file is returned as a response 
    (Content-Type: application/x-pkcs12).    
    
    The CA server also sends the freshly generated certificate + key pair 
    to the backup server, encrypted with the master backup public key.
    """
    user_info = request.get_json()
    for key, val in user_info.items():
        assert key in ["uid", "lastname", "firstname", "email"]
        assert isinstance(val, str)

    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    make_csr(user_info, tmp_csr.name, tmp_priv_key.name)


    # TODO don't forget to send cert.p12 encrypted to the backup server
    # TODO don't forget to delete the private key and cert.p12 file
    pass  # TODO


@app.post("/revoke-certificate")
def revoke_certificate():
    """
    This endpoint allows for certificate revocation.
    The body of the request contains a JSON object with the user id (uid) whose certificate must be revoked.
    E.g.:
    {"uid": "lb"}
    
    to revoke the certificate of Lukas Bruegger.
    Upon successful revocation, a response with status 204 No Content is sent back.
    If the user specified in the body of the request does not currently have a valid certificate,
    a response with status 404 Not Found is sent back.

    Docs: https://openssl-ca.readthedocs.io/en/latest/certificate-revocation-lists.html
    """
    pass # TODO

@app.get("/crl")
def get_crl():
    """
    This endpoint returns the current Certificate Revocation List (crl) of the CA.

    The crl is encoded in PEM format and the Content-Type is application/pkix-crl .
    See https://en.wikipedia.org/wiki/Certificate_revocation_list .
    """
    # see https://flask.palletsprojects.com/en/3.0.x/api/#flask.send_file
    pass # TODO

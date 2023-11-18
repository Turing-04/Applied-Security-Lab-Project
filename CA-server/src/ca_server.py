import subprocess
from flask import Flask, request, after_this_request, send_file, abort, make_response
import re
import tempfile
from typing import Dict, List
import os
from ca_database import CADatabase
from user_info import UserInfo, validate_user_info
from cert_utils import build_subj_str, make_csr,\
    sign_csr, export_pkcs12, revoke_cert, generate_crl, get_current_serial_nb

CA_PATH="/etc/ssl/CA" 
CA_DATABASE_PATH = f"{CA_PATH}/index.txt"
CA_CRL_PATH = f"{CA_PATH}/crl.pem"

app = Flask(__name__)



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

    openssl pkcs12 -export -out cert.p12 -inkey tmp.key\
         -in tmp.crt

    The cert.p12 file is returned as a response 
    (Content-Type: application/x-pkcs12).    
    
    The CA server also sends the freshly generated certificate + key pair 
    to the backup server, encrypted with the master backup public key.
    """
    user_info = request.get_json()
    validate_user_info(user_info)

    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8', delete=True)
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8', delete=True)
    make_csr(user_info, tmp_csr.name, tmp_priv_key.name)

    # Sign the certificate
    cert_path = sign_csr(tmp_csr.name)
    assert os.path.exists(cert_path), cert_path
    tmp_csr.close()

    # TODO don't forget to send cert.p12 encrypted to the backup server
    # TODO log https://flask.palletsprojects.com/en/3.0.x/logging/

    cert_and_key = export_pkcs12(cert_path, tmp_priv_key.name)
    tmp_priv_key.close()

    @after_this_request
    def delete_pkcs12(response):
        cert_and_key.close()
        return response

    response = send_file(cert_and_key.name, mimetype="application/x-pkcs12", max_age=0)
    return response




@app.post("/revoke-certificate")
def revoke_certificate():
    """
    This endpoint allows for certificate revocation.
    The body of the request contains a JSON object with the user info
    of the user whose certificate must be revoked.
    All the valid certificates who match the exact information given will
    be revoked (should normally be exactly 1).
    E.g.:
    {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
    
    to revoke the certificate of Lukas Bruegger.
    Upon successful revocation, a response with status 200 OK is sent back.
    If the user specified in the body of the request does not currently have a valid certificate,
    a response with status 404 Not Found is sent back.

    Docs: https://openssl-ca.readthedocs.io/en/latest/certificate-revocation-lists.html
    """
    user_info = request.get_json()
    validate_user_info(user_info)

    ca_db = CADatabase(CA_DATABASE_PATH)
    serial_nbs = ca_db.get_serial_numbers(user_info, valid_only=True)
    if len(serial_nbs) == 0:
        abort(404, description=f"No valid certificate for {user_info}")

    for serial_nb in serial_nbs:
        revoke_cert(serial_nb)
    
    generate_crl()

    return make_response('Certificate successfully revocated!', 200)

@app.get("/crl")
def get_crl():
    """
    This endpoint returns the current Certificate Revocation List (crl) of the CA.

    The crl is encoded in PEM format and the Content-Type is application/pkix-crl .
    See https://en.wikipedia.org/wiki/Certificate_revocation_list .
    """
    # see https://flask.palletsprojects.com/en/3.0.x/api/#flask.send_file
    
    return send_file(CA_CRL_PATH, mimetype="application/pkix-crl")

@app.get("/ca-state")
def get_ca_state():
    """
    ONLY THE CA ADMIN IS AUTHORIZED TO REQUEST THIS ENDPOINT.
    THE AUTHENTICATION IS DONE BY THE WEBSERVER!!!
    Returns a JSON object containing the CA's current state.
    E.g.
    {
        "nb_certs_issued": 42,
        "nb_certs_revoked": 5,
        "current_serial_nb": "1F"
    }

    Note: current_serial_nb is a string representing the hexadecimal value
    of the current serial number
    """
    ca_db = CADatabase(CA_DATABASE_PATH)
    
    state = {
        "nb_certs_issued": ca_db.nb_certs_issued(),
        "nb_certs_revoked": ca_db.nb_certs_revoked(),
        "current_serial_nb": get_current_serial_nb()
    }

    return state
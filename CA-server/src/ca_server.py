import subprocess
from flask import Flask, request, after_this_request, send_file, abort, make_response
import re
import tempfile
from typing import Dict, List
import os
from ca_database import CADatabase
from user_info import UserInfo, validate_user_info
from cert_utils import build_subj_str, make_csr,\
    sign_csr, export_pkcs12, revoke_cert, generate_crl, get_current_serial_nb,\
    verify_cert_valid
from mysql_utils import mysql_update_certificate, mysql_connect
from backup_utils import backup_pkcs12, ssh_connect
from logging.config import dictConfig
from mysql.connector import MySQLConnection
from fabric.connection import Connection

CA_PATH="/etc/ssl/CA" 
CA_DATABASE_PATH = f"{CA_PATH}/index.txt"
CA_CRL_PATH = f"{CA_PATH}/crl.pem"
MAX_CERT_LEN_BYTES = 6000

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

app = Flask(__name__)

global_mysql_cnx: MySQLConnection = None
global_ssh_cnx: Connection = None

@app.before_request
def ensure_remote_cnxs():
    global global_mysql_cnx
    if global_mysql_cnx is None:
        global_mysql_cnx = mysql_connect(app.logger, max_retries=2)
    elif not global_mysql_cnx.is_connected():
        global_mysql_cnx.close()
        global_mysql_cnx = mysql_connect(app.logger, max_retries=2)

    global global_ssh_cnx
    if global_ssh_cnx is None:
        global_ssh_cnx = ssh_connect(app.logger, max_retries=2)
    elif not global_ssh_cnx.is_connected:
        global_ssh_cnx.close()
        global_ssh_cnx = ssh_connect(app.logger, max_retries=2)


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

    app.logger.info(f"Signed new certificate for {user_info['uid']}")

    # update mysql db with new signed cert
    with open(cert_path, "r", encoding='utf-8') as cert_file:
        cert_str = cert_file.read()
        assert not cert_str is None
        mysql_update_certificate(global_mysql_cnx, user_info["uid"], cert_str, app.logger)

    pkcs12 = export_pkcs12(cert_path, tmp_priv_key.name)
    # send cert.p12 encrypted to the backup server
    backup_pkcs12(global_ssh_cnx, pkcs12, user_info["uid"], app.logger)

    tmp_priv_key.close()

    @after_this_request
    def delete_pkcs12(response):
        pkcs12.close()
        return response

    response = send_file(pkcs12.name, mimetype="application/x-pkcs12", max_age=0)
    return response




@app.post("/revoke-certificate")
def revoke_certificate():
    """
    This endpoint allows for certificate revocation.
    The body of the request contains a JSON object with the uid
    of the user whose certificate must be revoked.
    All the valid certificates for the uid will be revoked.
    E.g.:
    {"uid": "lb"}
    
    to revoke the certificate of Lukas Bruegger.
    Upon successful revocation, a response with status 200 OK is sent back.
    If the user specified in the body of the request does not currently have a valid certificate,
    a response with status 404 Not Found is sent back.

    Docs: https://openssl-ca.readthedocs.io/en/latest/certificate-revocation-lists.html
    """
    user_info = request.get_json()
    uid = user_info['uid']
    assert isinstance(uid, str), user_info

    ca_db = CADatabase(CA_DATABASE_PATH)
    serial_nbs = ca_db.get_serial_numbers(uid, valid_only=True)
    if len(serial_nbs) == 0:
        abort(404, description=f"No valid certificate for {user_info}")

    for serial_nb in serial_nbs:
        revoke_cert(serial_nb)

    # update mysql db to revoke certificate
    mysql_update_certificate(global_mysql_cnx, uid, 
        new_certificate=None, logger=app.logger)
    
    generate_crl()

    app.logger.info(f"Successfully revoked cert for {user_info}")

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

@app.post("/is-certificate-valid")
def is_certificate_valid():
    """
    Request: POST with Content-Type: application/pkix-cert
     body: PEM encoded certificate x509
    Response: {'is_valid': True} if the certificate is valid (not revoked)
        {'is_valid': False} if the certificate has been revoked
    """
    if request.content_length > MAX_CERT_LEN_BYTES:
        HTTP_PAYLOAD_TOO_LARGE = 413
        abort(HTTP_PAYLOAD_TOO_LARGE, description=f"Certificate too long: len(cert) > {MAX_CERT_LEN_BYTES}")
    
    cert_str = request.get_data(as_text=True)
    is_valid = verify_cert_valid(cert_str)
    return {'is_valid': is_valid}

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

@app.get("/ping")
def ping():
    # For testing
    app.logger.info("pong")
    return "pong"
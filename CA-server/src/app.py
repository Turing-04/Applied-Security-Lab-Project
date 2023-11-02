from flask import Flask

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
    TODO figure out how to not use interactive mode
    TODO make setuid script to make the signature as root

    openssl pkcs12 -export -out cert.p12 -inkey tmp.key\
         -in tmp.crt

    The cert.p12 file is returned as a response 
    (Content-Type: application/x-pkcs12).    
    
    The CA server also sends the freshly generated certificate + key pair 
    to the backup server, encrypted with the master backup public key.
    """

    # TODO don't forget to send cert.p12 encrypted to the backup server
    # TODO don't forget to delete the private key and cert.p12 file
    pass  # TODO

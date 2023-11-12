from flask import Flask

app = Flask(__name__)

@app.get("/ca-state")
def get_ca_state():
    """
    Returns a JSON object containing the CA's current state.
    E.g.
    {
        "nb_certs_issued": 42,
        "nb_certs_revoked": 5,
        "current_serial_nb": 42
    }
    """
    pass # TODO
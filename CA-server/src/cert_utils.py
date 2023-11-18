from user_info import UserInfo
import re
import tempfile
import os
import subprocess


OPENSSL_CMD = "openssl"

SIGN_CSR_SCRIPT_PATH = "./ca_sign_csr.sh"

CA_PATH="/etc/ssl/CA" 
CA_PASSWORD_PATH = f"{CA_PATH}/private/ca_password.txt"
CA_CONFIG_PATH = "/etc/ssl/openssl.cnf"
CA_SERIAL_PATH = f"{CA_PATH}/serial"

OPENSSL_KEY_PARAMS = "rsa:2048"

def build_subj_str(user_info: UserInfo) -> str:
    out = "/C=CH/ST=Zurich/O=iMovies"

    firstname = user_info["firstname"]
    lastname = user_info["lastname"]
    assert firstname.isalpha(), firstname
    assert lastname.isalpha(), lastname
    out += f"/CN={firstname} {lastname}"

    email_regex = r"\w+@\w+\.\w+"
    email = user_info["email"]
    assert bool(re.match(email_regex, email)), email
    out += f"/emailAddress={email}"
    
    return out

def export_pkcs12(cert_path: str, key_path: str) -> tempfile.NamedTemporaryFile:
    """
    `openssl pkcs12 -export -in /etc/ssl/CA/newcerts/02.pem -inkey tmp.key 
        -out cert_key.p12 -passout pass:`
    TODO this exports the private key WITHOUT encryption. Maybe we should encrypt
    with the user password
    """
    assert os.path.exists(cert_path)
    assert os.path.exists(key_path)

    pkcs12 = tempfile.NamedTemporaryFile(delete=True)

    cmd = [OPENSSL_CMD, "pkcs12", "-export"]
    cmd += ["-in", cert_path]
    cmd += ["-inkey", key_path]
    cmd += ["-out", pkcs12.name]
    cmd += ["-passout", "pass:"] # TODO no encryption for private key?

    subprocess.run(cmd, check=True)

    return pkcs12


def sign_csr(csr_path: str) -> str:
    """
    #  Now we are ready to sign certificates. Given a certificate signing request
    # (e.g., key.csr), the following command will generate a certificate signed
    # by Alice's CA:
    sudo openssl ca -in key.csr -config /etc/ssl/openssl.cnf
    The certificate is then saved in /etc/ssl/CA/newcerts/ as
    <serial-number>.pem.
    """
    assert os.path.exists(csr_path), csr_path

    out = subprocess.run([SIGN_CSR_SCRIPT_PATH, csr_path, CA_PASSWORD_PATH], 
        capture_output=True, text=True, check=False)
    assert out.returncode == 0, f"Failed to sign {csr_path}"
    out.check_returncode()
    
    signed_cert_path = out.stdout.strip()
    return signed_cert_path



def make_csr(user_info: UserInfo, tmp_csr_path: str, tmp_priv_key_path: str) -> None:
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

def revoke_cert(serial_nb: str):
    """
    # sudo openssl ca -revoke /etc/ssl/CA/newcerts/03.pem -config /etc/ssl/openssl.cnf 
    # -passin file:/etc/ssl/CA/private/ca_password.txt
    """
    cmd = ["sudo", OPENSSL_CMD, "ca"]
    cmd += ["-revoke", f"{CA_PATH}/newcerts/{serial_nb}.pem"]
    cmd += ["-config", CA_CONFIG_PATH]
    cmd += ["-passin", f"file:{CA_PASSWORD_PATH}"]

    subprocess.run(cmd, check=True)

def generate_crl():
    """
    # sudo openssl ca -config /etc/ssl/openssl.cnf -gencrl \
    # -out "$CA_PATH/crl.pem" -passin file:"$CA_PATH/private/ca_password.txt"
    """
    cmd = ["sudo", OPENSSL_CMD, "ca"]
    cmd += ["-config", CA_CONFIG_PATH]
    cmd += ["-passin", f"file:{CA_PASSWORD_PATH}"]
    cmd += ["-gencrl"]
    cmd += ["-out", f"{CA_PATH}/crl.pem"]

    subprocess.run(cmd, check=True)

def get_current_serial_nb() -> str:
    """
    Gets the current value stored in /etc/ssl/CA/serial
    """
    serial = ""
    with open(CA_SERIAL_PATH, 'r', encoding='utf-8') as serial_file:
        serial = serial_file.read().strip()
    assert serial != "", "Empty /etc/ssl/CA/serial file!"

    return serial
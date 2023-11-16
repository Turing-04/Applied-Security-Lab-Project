from ca_server import *
import pytest
import tempfile
import base64
import secrets
import string

DUMMY_USER_INFO = {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
DUMMY_SUBJ_STR = "/C=CH/ST=Zurich/O=iMovies/CN=Lukas Bruegger/emailAddress=lb@imovies.ch/"

def test_build_subj_str():
    assert build_subj_str(DUMMY_USER_INFO) == DUMMY_SUBJ_STR

    inj_attempt = DUMMY_USER_INFO.copy()
    with pytest.raises(AssertionError):
        inj_attempt["firstname"] = "Lukas/emailAddress=ca-admin.ch"
        build_subj_str(inj_attempt)
    
    inj_attempt = DUMMY_USER_INFO.copy()
    with pytest.raises(AssertionError):
        inj_attempt["lastname"] = "Bruegger/emailAddress=ca-admin.ch"
        build_subj_str(inj_attempt)

def test_make_csr():
    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8')

    make_csr(DUMMY_USER_INFO, tmp_csr.name, tmp_priv_key.name)

    csr = tmp_csr.read()
    priv_key = tmp_priv_key.read()

    assert csr.startswith('-----BEGIN CERTIFICATE REQUEST-----')
    assert priv_key.startswith('-----BEGIN PRIVATE KEY-----')



def generate_random_string(length):
    characters = string.ascii_letters
    random_string = ''.join(secrets.choice(characters) for _ in range(length))
    return random_string

def test_sign_csr():
    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8')

    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(50)

    make_csr(user_info, tmp_csr.name, tmp_priv_key.name)

    csr = tmp_csr.read()
    priv_key = tmp_priv_key.read()

    cert_path = sign_csr(tmp_csr.name)
    assert os.path.exists(cert_path)
    
    with open(cert_path) as cert:
        cert_str = cert.read()
        # print(len(bytes(cert_str.encode('utf-8'))))
        assert cert_str.startswith("Certificate")
        for v in user_info.values():
            assert v in cert_str

def test_export_pkcs12():
    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8')

    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(10)

    make_csr(user_info, tmp_csr.name, tmp_priv_key.name)

    csr = tmp_csr.read()
    priv_key = tmp_priv_key.read()

    cert_path = sign_csr(tmp_csr.name)
    # print(cert_path)

    pkcs12 = export_pkcs12(cert_path, tmp_priv_key.name)
    assert os.path.exists(pkcs12.name)

    # openssl pkcs12 -in cert_key.p12 -passin pass: -noenc
    read_cmd = ["openssl", "pkcs12", "-in", pkcs12.name, "-passin", "pass:", "-noenc"]
    read_pkcs12 = subprocess.run(read_cmd, capture_output=True, check=False, text=True)

    print(read_pkcs12.stdout, read_pkcs12.stderr)

    for v in user_info.values():
        assert v in read_pkcs12.stdout

    assert "-----BEGIN CERTIFICATE-----" in read_pkcs12.stdout

    assert read_pkcs12.stdout.endswith("-----END PRIVATE KEY-----\n")

def test_export_many_certs():
    for i in range(300):
        test_export_pkcs12()


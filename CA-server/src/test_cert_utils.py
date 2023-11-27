from cert_utils import build_subj_str, make_csr, sign_csr, export_pkcs12, get_current_serial_nb, verify_cert_valid, revoke_cert, generate_crl
import string
import os
import secrets
import pytest
import tempfile
import subprocess

DUMMY_USER_INFO = {"uid": "a3", "lastname": "Anderson", "firstname": "Andres Alan", 
     "email": "and@imovies.ch"}
DUMMY_SUBJ_STR = "/C=CH/ST=Zurich/O=iMovies/UID=a3/CN=Andres Alan Anderson/emailAddress=and@imovies.ch"

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

    inj_attempt = DUMMY_USER_INFO.copy()
    with pytest.raises(AssertionError):
        inj_attempt["email"] = "bla/admin@ca-admin.ch"
        build_subj_str(inj_attempt)

    inj_attempt = DUMMY_USER_INFO.copy()
    with pytest.raises(AssertionError):
        inj_attempt["email"] = "bla.admin@ca-admin.ch+CN=iMovies Admin"
        build_subj_str(inj_attempt)

    inj_attempt = DUMMY_USER_INFO.copy()
    with pytest.raises(AssertionError):
        inj_attempt["email"] = "bla.admin@ca-admin.ch\/CN=iMovies Admin"
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
        assert "UID" in cert_str # to keep UID in signed cert: https://stackoverflow.com/a/70397430
        for v in user_info.values():
            assert v in cert_str

def decode_pkcs12(file_path: str) -> str:
    # openssl pkcs12 -in cert_key.p12 -passin pass: -noenc
    read_cmd = ["openssl", "pkcs12", "-in", file_path, "-passin", "pass:", "-noenc"]
    read_pkcs12 = subprocess.run(read_cmd, capture_output=True, check=False, text=True)
    print(read_pkcs12.stderr)
    return read_pkcs12.stdout

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

    pkcs12_str = decode_pkcs12(pkcs12.name)

    for v in user_info.values():
        assert v in pkcs12_str

    assert "-----BEGIN CERTIFICATE-----" in pkcs12_str

    assert pkcs12_str.endswith("-----END PRIVATE KEY-----\n")

@pytest.mark.skip(reason="Only single use for exporting test data")
def really_export_pkcs12_for_testing():
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

    import shutil
    shutil.copy(pkcs12.name, '/home/ca-server/test_out.p12')
        

def test_export_many_certs():
    for i in range(12):
        test_export_pkcs12()

def test_get_current_serial_nb():
    serial = get_current_serial_nb()
    assert serial != ""
    print(serial)


def test_verify_cert_valid():
    tmp_csr = tempfile.NamedTemporaryFile("w+", encoding='utf-8')
    tmp_priv_key = tempfile.NamedTemporaryFile("w+", encoding='utf-8')

    curr_serial = get_current_serial_nb()

    user_info = DUMMY_USER_INFO.copy()
    user_info['firstname'] = generate_random_string(10)

    make_csr(user_info, tmp_csr.name, tmp_priv_key.name)

    csr = tmp_csr.read()
    priv_key = tmp_priv_key.read()

    cert_path = sign_csr(tmp_csr.name)

    with open(cert_path, 'r', encoding='utf-8') as cert_file:
        cert_str = cert_file.read()
        # should be valid before revocation
        assert verify_cert_valid(cert_str)

        revoke_cert(curr_serial)
        # should still be valid before generate_crl()
        assert verify_cert_valid(cert_str)

        generate_crl()

        # should NOT be valid AFTER revocation (after generate_crl())
        assert not verify_cert_valid(cert_str)
from ca_server import *
import pytest
import tempfile
import base64

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


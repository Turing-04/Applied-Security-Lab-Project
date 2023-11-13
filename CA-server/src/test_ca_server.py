from ca_server import *
import pytest

DUMMY_USER_INFO = {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
DUMMY_SUBJ_STR = "/C=CH/O=iMovies/CN=Lukas Bruegger/emailAddress=lb@imovies.ch/"

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
    # make_csr(DUMMY_USER_INFO)
    # TODO make tmp dir for tmp data
    pass

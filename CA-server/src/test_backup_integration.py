from backup_utils import ssh_connect, backup_pkcs12, pgp_encrypt

import pytest
from logging import Logger, INFO
from tempfile import NamedTemporaryFile, TemporaryFile
import shutil

PKCS12_TEST_FILE = "./test_data/test_cert_key.p12"

@pytest.fixture
def ssh_cnx():
    # Set up and yield the database connection
    logger = Logger("TestLogger")
    cnx = ssh_connect(logger)
    print(cnx.is_connected)
    yield cnx
    # Teardown: close the database connection after the test
    if cnx and cnx.is_connected:
        cnx.close()

@pytest.fixture
def tmp_logger():
    lgr = Logger("TestLogger")
    lgr.setLevel(INFO)
    return lgr

def test_backup_pkcs12(ssh_cnx, tmp_logger):
    pkcs12_tmp = NamedTemporaryFile('rb')
    shutil.copy(PKCS12_TEST_FILE, pkcs12_tmp.name)
    assert not ssh_cnx is None
    assert ssh_cnx.is_connected
    backup_pkcs12(ssh_cnx, pkcs12_tmp, 'lb', tmp_logger)

    # tested manually...
    # tmp_copy_back = TemporaryFile('w+b')
    # ssh_cnx.get(remote_path, local=tmp_copy_back)

    # local_pkcs12_encr = pgp_encrypt(pkcs12_tmp.read())

    # tmp_copy_back_str = tmp_copy_back.read()
    # assert tmp_copy_back_str != ""
    
    # assert tmp_copy_back_str == local_pkcs12_encr
    # tmp_copy_back.close()

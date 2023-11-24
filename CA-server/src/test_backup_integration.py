from backup_utils import ssh_connect, backup_pkcs12

import pytest
from logging import Logger
from tempfile import NamedTemporaryFile
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
    return Logger("TestLogger")

def test_backup_pkcs12(ssh_cnx, tmp_logger):
    pkcs12_tmp = NamedTemporaryFile('rb')
    shutil.copy(PKCS12_TEST_FILE, pkcs12_tmp.name)
    backup_pkcs12(ssh_cnx, pkcs12_tmp, 'lb', tmp_logger)

import pytest
from logging import Logger

# Import your functions and constants from the module
from mysql_utils import mysql_connect, mysql_update_certificate, mysql_get_certificate

import random

DUMMY_CERT_STR = """-----BEGIN CERTIFICATE-----
MIIDZTCCAk0CFC6IukzPJvoJyCMb7Z4ak83G0ggiMA0GCSqGSIb3DQEBCwUAMHAx
CzAJBgNVBAYTAkNIMQ8wDQYDVQQIDAZadXJpY2gxEDAOBgNVBAoMB2lNb3ZpZXMx
GjAYBgNVBAMMEWlNb3ZpZXMgcm9vdCBjZXJ0MSIwIAYJKoZIhvcNAQkBFhNjYS1h
ZG1pbkBpbW92aWVzLmNoMB4XDTIzMTEyMjExMDYzMloXDTI0MTEyMTExMDYzMlow
bjELMAkGA1UEBhMCQ0gxDzANBgNVBAgMBlp1cmljaDEQMA4GA1UECgwHaU1vdmll
czERMA8GA1UEAwwIMTAuMC4wLjMxKTAnBgkqhkiG9w0BCQEWGmNhLXNlcnZlci1t
eXNxbEBpbW92aWVzLmNoMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
3s/+S5d3KME7mpwtbygRy5JYj+0D55PjBemGY9JzOjYjrjrS5fmr+E348KcF8vth
PrV3DXjT0VtHXVQNtHFPSl9tdBo9XQvw3DMiTsoe9vkDwCoMJn1wLkyh8nAAhW1g
StWNoH1ugtlphIr/LDIzxHKKHZGPa0StanU7P/gJyx5/l9lGdGPu16XtgxCkZyiN
psdua7aBq38HQ4XG9F1nskDu/+jU/GGbfallyH1EGc4ufojUCqqoPvEASidwoWvd
58qevcMYcutkBNiM4uzRuu9wgtYAn8LJRtaFwrYya77BN80SZf3LcZNoV3/0rslW
mqO2atyxZFV3geFviopbSwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQAmIB+bzoJr
Oj21xSY0NHgYXBsiLEQ8QJQ4h4rR9akQ8IeIQUq7LmN1NOcuNrvCnY+qFDcQq1GR
sI1XoN+HfUFhEiEgd0H/4jB7R1b0bi72pSx9W0soy9j8MSI2KBFcFyFN0mHzXcoI
nHnF6s2W2wv41bD7dPfaRVIOn0zOGKHC/Ekb1R0u7nBx/nLFcvdjBoxcQfMYAG40
gVpJVxmnIREwVKbYLzXX7/apy54P1JRUe9eI2g6ztTMGR8JIVgdhkiz/eKWK4xPt
quh6za9q142cvEWtloBB34lI7ABy4mZPUpR9075LSv6u+Q1DlZCd2jOEuX12osR9
6BSqgKcLqjgB
-----END CERTIFICATE-----
"""

@pytest.fixture
def db_connection():
    # Set up and yield the database connection
    logger = Logger("TestLogger")
    max_retries = 3
    connection = mysql_connect(logger, max_retries=max_retries)
    print(connection.is_connected())
    yield connection
    # Teardown: close the database connection after the test
    if connection and connection.is_connected():
        connection.close()

def test_update_and_query_certificate(db_connection):
    # Set test data
    user_id = "lb"
    new_certificate = f"{DUMMY_CERT_STR}{random.randint(1, 10000)}"

    try:
        # Perform the update
        mysql_update_certificate(db_connection, user_id, new_certificate, Logger("TestLogger"))

        # Query the updated certificate
        retrieved_certificate = mysql_get_certificate(db_connection, user_id, Logger("TestLogger"))

        # Assert that the retrieved certificate matches the updated certificate
        assert retrieved_certificate == new_certificate

    except Exception as e:
        # Log any exceptions and fail the test
        Logger("TestLogger").error(f"Test failed with exception: {e}")
        assert False, "Test failed"

def test_update_and_revoke_certificate(db_connection):
    # Set test data
    user_id = "lb"
    new_certificate = f"{DUMMY_CERT_STR}{random.randint(1, 10000)}"
    logger = Logger("TestLogger")

    # Perform the update
    mysql_update_certificate(db_connection, user_id, new_certificate, logger)

    # Query the updated certificate
    retrieved_certificate = mysql_get_certificate(db_connection, user_id, logger)

    # Assert that the retrieved certificate matches the updated certificate
    assert retrieved_certificate == new_certificate

    # revoke 
    mysql_update_certificate(db_connection, user_id, None, logger)

    retrieved_certificate = mysql_get_certificate(db_connection, user_id, logger)

    assert retrieved_certificate is None

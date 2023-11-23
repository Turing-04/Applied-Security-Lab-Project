import pytest
from logging import Logger

# Import your functions and constants from the module
from mysql_utils import mysql_connect, mysql_update_certificate, mysql_get_certificate

import random

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
    new_certificate = f"test_certificate_data{random.randint(1, 10000)}"

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
    new_certificate = f"test_certificate_data{random.randint(1, 10000)}"
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

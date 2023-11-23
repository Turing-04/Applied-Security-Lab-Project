from mysql.connector import MySQLConnection
import mysql.connector
import sys
from logging import Logger

MYSQL_HOST = "10.0.0.5"
MYSQL_PORT = 3306
# user/password from https://github.com/Turing-04/Applied-Security-Lab-Project/blob/bd1c55e4da94093188e3de841d928ffda9428224/mysql_server/scripts/setup_mysql.sh#L40
MYSQL_USER = "caserver"
MYSQL_PASSWORD = "cn9@1kbka;}=(iPgEMO1&{XW"
MYSQL_DATABASE = "imovies"
MYSQL_CLIENT_CERT_PATH="/etc/ssl/certs/ca-server-mysql.crt"
MYSQL_CLIENT_KEY_PATH="/etc/ssl/private/ca-server-mysql.key"
CA_CERT_PATH="/etc/ssl/CA/cacert.pem"

def mysql_connect(logger: Logger, max_retries: int = 5) -> MySQLConnection:
    cnx = None
    is_connected = False
    retries = 0
    while not is_connected and retries < max_retries:
        try:
            # Connect to the server
            cnx = mysql.connector.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DATABASE,
                ssl_ca=CA_CERT_PATH, # File containing the SSL certificate authority.
                ssl_cert=MYSQL_CLIENT_CERT_PATH, # File containing the SSL certificate file.
                ssl_key=MYSQL_CLIENT_KEY_PATH, # File containing the SSL key.
                ssl_verify_cert=True, # When set to True, checks the server certificate 
                # against the certificate file specified by the ssl_ca option. 
                # Any mismatch causes a ValueError exception.
            )
            is_connected = True # no error
        except mysql.connector.Error as err:
            logger.error(err)
        retries += 1
        
    return cnx


def mysql_update_certificate(cnx: MySQLConnection, uid: str, new_certificate: str, logger: Logger):
    """
    Update or revoke a certificate for a given user ID (UID) in a MySQL database.

    Parameters:
    - cnx (MySQLConnection): MySQL database connection.
    - uid (str): User ID for whom the certificate is to be updated or revoked.
    - new_certificate (str): New certificate to be assigned. Pass None to revoke the certificate.
    - logger (Logger): Logger object for capturing and recording log information.

    Raises:
    - mysql.connector.Error: If an error occurs during the MySQL database operation.

    Note:
    - This function assumes a 'certificates' table with columns 'uid' and 'certificate' in the MySQL database.

    Example Usage:
    ```python
    mysql_update_certificate(db_connection, 'user123', 'new_cert_data', app_logger)
    ```

    """
    assert cnx != None
    try:
        # Get a cursor
        cur = cnx.cursor()

        action_revoke = new_certificate is None
        if action_revoke:
            # i.e. we want to revoke
            update_query = "UPDATE certificates SET certificate = NULL WHERE uid = %s"
            cur.execute(update_query, (uid,))
        else:
            # Update the certificate for the given UID
            update_query = "UPDATE certificates SET certificate = %s WHERE uid = %s"
            # update_query = "INSERT INTO certificates (certificate, uid) VALUES (%s, %s)"
            cur.execute(update_query, (new_certificate, uid))

        # Commit the changes
        cnx.commit()

        if action_revoke:
            logger.info(f"Successfully revoked cert for UID={uid} in MySQL")
        else:
            logger.info(f"Successfully updated cert for UID={uid} in MySQL.")

    except mysql.connector.Error as err:
        logger.error(f"Error: {err},\nwhile trying to update {uid} with {new_certificate}")

    finally:
        if cur:
            cur.close()


def mysql_get_certificate(cnx: MySQLConnection, uid: str, logger: Logger) -> str:
    """
    ONLY FOR TESTING!!!
    Retrieve the certificate for a given user ID (UID) from a MySQL database.

    Parameters:
    - cnx (MySQLConnection): MySQL database connection.
    - uid (str): User ID for whom the certificate is to be retrieved.
    - logger (Logger): Logger object for capturing and recording log information.

    Returns:
    - str: Certificate associated with the specified user ID.

    Raises:
    - mysql.connector.Error: If an error occurs during the MySQL database operation.

    Note:
    - This function assumes a 'certificates' table with columns 'uid' and 'certificate' in the MySQL database.

    Example Usage:
    ```python
    certificate_data = mysql_get_certificate(db_connection, 'user123', app_logger)
    ```

    """
    assert cnx is not None
    try:
        # Get a cursor
        cur = cnx.cursor()

        # Query the certificate for the given UID
        query = "SELECT certificate FROM certificates WHERE uid = %s"
        cur.execute(query, (uid,))

        # Fetch the result
        result = cur.fetchone()

        if result is not None:
            certificate = result[0]
            logger.info(f"Successfully retrieved certificate for UID={uid} from MySQL.")
            return certificate
        else:
            logger.info(f"No certificate found for UID={uid} in MySQL.")
            return None

    except mysql.connector.Error as err:
        logger.error(f"Error: {err},\nwhile trying to retrieve certificate for UID={uid}")

    finally:
        if cur:
            cur.close()

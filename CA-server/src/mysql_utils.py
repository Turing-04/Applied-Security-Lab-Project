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

def mysql_connect(logger: Logger) -> MySQLConnection:
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
    return cnx


def mysql_update_certificate(cnx: MySQLConnection, uid: str, new_certificate: str, logger: Logger):
    assert cnx != None
    try:
        # Get a cursor
        cur = cnx.cursor()

        # Update the certificate for the given UID
        update_query = "UPDATE certificates SET certificate = %s WHERE uid = %s"
        cur.execute(update_query, (new_certificate, uid))

        # Commit the changes
        cnx.commit()

        logger.info(f"Certificate for UID {uid} updated successfully.")

    except mysql.connector.Error as err:
        logger.error(f"Error: {err},\nwhile trying to update {uid} with {new_certificate}")

    finally:
        # Close the connection
        if cnx and cnx.is_connected():
            cur.close()
            cnx.close()

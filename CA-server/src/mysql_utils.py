import mysql.connector
import sys

MYSQL_HOST = "10.0.0.5"
MYSQL_PORT = 3306
MYSQL_USER = "ca-server"
MYSQL_PASSWORD = "caserver123" # TODO maybe this will change...
MYSQL_DATABASE = "imovies"
MYSQL_CLIENT_CERT_PATH="/etc/ssl/certs/ca-server-intranet.crt"
MYSQL_CLIENT_KEY_PATH="/etc/ssl/private/ca-server-intranet.key"
CA_CERT_PATH="/etc/ssl/CA/cacert.pem"


def mysql_update_certificate(uid: str, new_certificate: str):
    cnx = None
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

        # Get a cursor
        cur = cnx.cursor()

        # Update the certificate for the given UID
        update_query = "UPDATE certificates SET certificate = %s WHERE uid = %s"
        cur.execute(update_query, (new_certificate, uid))

        # Commit the changes
        cnx.commit()

        print(f"Certificate for UID {uid} updated successfully.")

    except mysql.connector.Error as err:
        print(f"Error: {err}", file=sys.stderr)
        print(f"While trying to update {uid} with {new_certificate}", file=sys.stderr)

    finally:
        # Close the connection
        if cnx and cnx.is_connected():
            cur.close()
            cnx.close()

import mysql.connector

MYSQL_HOST = "10.0.0.5"
MYSQL_PORT = 3306
MYSQL_USER = "ca-server"
MYSQL_PASSWORD = "TODO_SET_USER_PASSWORD"
MYSQL_DATABASE = "imovies"

def update_certificate(uid: str, new_certificate: str):
    try:
        # Connect to the server
        cnx = mysql.connector.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE,
            ssl_ca="TODO", # File containing the SSL certificate authority.
            ssl_cert="TODO", # File containing the SSL certificate file.
            ssl_key="TODO", # File containing the SSL key.
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
        print(f"Error: {err}")

    finally:
        # Close the connection
        if cnx.is_connected():
            cur.close()
            cnx.close()

# Example usage:
# Replace 'your_uid' and 'your_new_certificate' with actual values
update_certificate('your_uid', 'your_new_certificate')

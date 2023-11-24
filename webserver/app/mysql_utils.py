from mysql.connector import MySQLConnection
import mysql.connector
import sys

MYSQL_HOST = "10.0.0.5"
MYSQL_PORT = 3306
# user/password from https://github.com/Turing-04/Applied-Security-Lab-Project/blob/bd1c55e4da94093188e3de841d928ffda9428224/mysql_server/scripts/setup_mysql.sh#L40
MYSQL_USER = "caserver"
MYSQL_PASSWORD = "cn9@1kbka;}=(iPgEMO1&{XW"
MYSQL_DATABASE = "imovies"
MYSQL_CLIENT_CERT_PATH="/etc/ssl/certs/ca-server-mysql.crt"
MYSQL_CLIENT_KEY_PATH="/etc/ssl/private/ca-server-mysql.key"
CA_CERT_PATH="/etc/ssl/CA/cacert.pem"

def db_auth(username, password):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH)
    except mysql.connector.Error as err:
        print("Something went wrong: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE username = %s AND password = %s", (username, password))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result is not None


def db_update_info(firstname, lastname, email, username):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH)
    except mysql.connector.Error as err:
        print("Something went wrong: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET firstname = %s,\
                   lastname = %s, email= = %s WHERE username=%s" , (firstname, lastname, email, username))
    conn.commit()
    cursor.close()
    conn.close()
    return True
        
def db_update_passwd(new_passwd, username):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH)
    except mysql.connector.Error as err:
        print("Something went wrong: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET password = %s WHERE username=%s" , (new_passwd, username))
    conn.commit()
    cursor.close()
    conn.close()
    return True

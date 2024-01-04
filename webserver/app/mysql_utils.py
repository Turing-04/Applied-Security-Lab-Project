from mysql.connector import MySQLConnection
import mysql.connector
import sys
import hashlib
import tempfile

MYSQL_HOST = "10.0.0.5"
MYSQL_PORT = 3306
MYSQL_USER = "webserver"
MYSQL_PASSWORD = "}DqG3mZ8neKPp?#Uc?49K&W2"
MYSQL_DATABASE = "imovies"
MYSQL_CLIENT_CERT_PATH="/etc/ssl/certs/webserver-intranet.crt"
MYSQL_CLIENT_KEY_PATH="/etc/ssl/private/webserver-intranet.key"
CA_CERT_PATH="/etc/ssl/certs/cacert.pem"


def db_auth(user_id, password, logger):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, 
                               host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, 
                               ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, 
                               ssl_key=MYSQL_CLIENT_KEY_PATH,
                               ssl_verify_cert=True)
    except mysql.connector.Error as err:
        logger.error("Connection to DB for authentification failed: {}".format(err))
        return None
    
    cursor = conn.cursor()
    cursor.execute("SELECT pwd FROM users WHERE uid = %s", (user_id,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    
    print("SQL result:", result)
    
    hashed_pwd = hashlib.sha256(password.encode('utf-8')).hexdigest()
    if result is not None and result[0] == hashed_pwd:
        return True
    else:
        return False

def db_update_info(firstname, lastname, email, user_id, logger):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH, ssl_verify_cert=True)
    except mysql.connector.Error as err:
        logger.error("Connection to DB for user info update failed: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET firstname = %s,\
                   lastname = %s, email = %s WHERE uid=%s" , (firstname, lastname, email, user_id))
    conn.commit()
    cursor.close()
    conn.close()
    return db_info(user_id, logger)

    
        
def db_update_passwd(new_passwd, user_id, logger):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH, ssl_verify_cert=True)
    except mysql.connector.Error as err:
        logger.error("Connection to DB for password update failed: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("UPDATE users SET pwd = %s WHERE uid=%s" , (new_passwd, user_id))
    result = cursor.fetchone()
    conn.commit()
    cursor.close()
    conn.close()
    print("SQL result:", result)
    print("updated passwd for user", user_id)
    return True

def db_info(user_id, logger):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH, ssl_verify_cert=True)
    except mysql.connector.Error as err:
        logger.error("Connection to DB for user info retrieval failed: {}".format(err))
        return None
    cursor = conn.cursor()
    cursor.execute("SELECT firstname, lastname, email FROM users WHERE uid = %s", (user_id,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result
    
  

def db_get_client_cert(user_id, logger):
    try:
        conn = MySQLConnection(user=MYSQL_USER, password=MYSQL_PASSWORD, host=MYSQL_HOST, port=MYSQL_PORT, database=MYSQL_DATABASE, ssl_ca=CA_CERT_PATH, ssl_cert=MYSQL_CLIENT_CERT_PATH, ssl_key=MYSQL_CLIENT_KEY_PATH, ssl_verify_cert=True)
    except mysql.connector.Error as err:
        logger.error("Connection to DB for client cert retrieval failed: {}".format(err))
        return None
    
    logger.info("Connected to DB for client cert retrieval")
    cursor = conn.cursor()
    cursor.execute("SELECT certificate FROM certificates WHERE uid = %s", (user_id,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    if result[0] is None: # no cert in db
        logger.info("No certificate found in DB for user {}".format(user_id))
        return None
    temp = tempfile.NamedTemporaryFile("w+b", delete=True)
    temp.write(result[0].encode('utf-8'))
    temp.write(b"\n")
    temp.flush()
    return temp
    

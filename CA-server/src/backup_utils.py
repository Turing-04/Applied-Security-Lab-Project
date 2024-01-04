from logging import Logger
from fabric.connection import Connection
from pgpy import PGPKey, PGPMessage
import tempfile
from datetime import datetime
from paramiko.ssh_exception import SSHException, NoValidConnectionsError

BKP_SERVER_IP="10.0.0.4"
# BKP_SERVER_USER="caserver"
# SSH_KEY_FILENAME="/home/ca-server/.ssh/ca-server-ssh/ca-server-ssh"
BKP_CERTS_PATH="/backup/caserver/keys_certs"
BKP_MASTER_PUBLIC_KEY="/home/ca-server/gpg-public/bkp-master-key-public.gpg"

def ssh_connect(logger: Logger, max_retries = 1) -> Connection:
    """
    This function establishes an SSH connection to the backup server using Fabric's Connection class.

    Parameters:
    - logger: logging.Logger
    A logger object to record log messages.

    Returns:
    - Connection
    A Fabric Connection object representing the SSH connection.
    """
    cnx = None
    is_connected = False
    retries = 0
    while not is_connected and retries < max_retries:
        try:
            # everything is already configured in ~/.ssh/config
            # can set low connect timeout in local net with RTT ~ 1ms
            cnx = Connection(host=BKP_SERVER_IP, connect_timeout=1)
            cnx.open()
            is_connected = cnx.is_connected
            logger.info(f"SSH: connect retry {retries} success? {is_connected} ({BKP_SERVER_IP})")
        except Exception as e:
            logger.error(f"SSH: {e} while trying to establish a connection\
                to {BKP_SERVER_IP}. retries={retries}")
            if cnx:
                cnx.close()
        finally:
            retries += 1
    
    if cnx.is_connected:
        logger.info(f"SSH: Successfully connected to backup server ({BKP_SERVER_IP})")
    return cnx

def pgp_encrypt(data: str) -> str:
    """
    This function encrypts a string of data using PGP encryption.

    Parameters:
    - data: str
    The input data to be encrypted.

    Returns:
    - str
        The encrypted data in PGP format.
    """
    pubkey, _ = PGPKey.from_file(BKP_MASTER_PUBLIC_KEY)
    plaintext = PGPMessage.new(data)
    ciphertext = pubkey.encrypt(plaintext)
    return str(ciphertext)


def backup_pkcs12(ssh_cnx: Connection, pkcs12_file: tempfile.TemporaryFile, uid: str, logger: Logger) -> str:
    """
    This function securely backs up a PKCS12 file to a remote server using PGP encryption.

    Parameters:
    - ssh_cnx: Connection
    A Fabric Connection object representing the SSH connection to the backup server.
    - pkcs12_file: tempfile.TemporaryFile
    A temporary file object containing the PKCS12 data to be backed up.
    - uid: str
    A unique identifier used in the backup file name.
    - logger: logging.Logger
    A logger object to record log messages.
    """
    assert uid != ""
    assert not pkcs12_file is None
    assert not ssh_cnx is None
    assert ssh_cnx.is_connected, "backup_pkcs12: ssh_cnx not connected, better fail"
    time = datetime.now().strftime('%Y-%m-%dT%H-%M-%S')
    dst_file_name = f"{time}_{uid}.p12.gpg"
    destination_path = f"{BKP_CERTS_PATH}/{dst_file_name}"

    pkcs12_data = pkcs12_file.read()

    encrypted_file = tempfile.TemporaryFile("r+", encoding='utf-8')
    encrypted_file.write(pgp_encrypt(pkcs12_data))
    ssh_cnx.put(encrypted_file, remote=destination_path)

    logger.info(f"Successfully backed up temp pkcs12 to {destination_path} on {BKP_SERVER_IP}")
    return destination_path

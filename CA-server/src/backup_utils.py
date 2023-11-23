from logging import Logger
from fabric.connection import Connection
from pgpy import PGPKey, PGPMessage
import tempfile
from datetime import datetime

BKP_SERVER_IP="10.0.0.4"
BKP_SERVER_USER="caserver"
BKP_CERTS_PATH="/backup/caserver/keys_certs"
# ENCRYPT_KEY_ID = "master-backup-key@imovies.ch"
# GPG_HOMEDIR="/home/ca-server/.gnupg/"
# GPG_KEYRING="pubring.kbx"
BKP_MASTER_PUBLIC_KEY="/home/ca-server/gpg-public/bkp-master-key-public.gpg"

def ssh_connect(logger: Logger) -> Connection:
    cnx = Connection(BKP_SERVER_IP, user=BKP_SERVER_USER, port=22)
    if cnx.is_connected:
        logger.info(f"Successfully connected to backup server ({BKP_SERVER_IP})")
    else:
        logger.error(f"Error connecting to backup server ({BKP_SERVER_IP})")
    return cnx

def pgp_encrypt(data: str) -> str:
    pubkey, _ = PGPKey.from_file(BKP_MASTER_PUBLIC_KEY)
    plaintext = PGPMessage.new(data)
    ciphertext = pubkey.encrypt(plaintext)
    return str(ciphertext)


def backup_pkcs12(ssh_cnx: Connection, pkcs12_file: tempfile.TemporaryFile, uid: str, logger: Logger):
    assert uid != ""
    assert not pkcs12_file is None
    assert not ssh_cnx is None
    time = datetime.now().strftime('%Y-%m-%dT%H-%M-%S')
    dst_file_name = f"{time}_{uid}.p12.gpg"
    destination_path = f"{BKP_CERTS_PATH}/{dst_file_name}"

    pkcs12_data = pkcs12_file.read()

    encrypted_file = tempfile.TemporaryFile("w", encoding='utf-8')
    encrypted_file.write(pgp_encrypt(pkcs12_data))
    ssh_cnx.put(encrypted_file, remote=destination_path)

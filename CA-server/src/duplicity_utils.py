import subprocess
import time

BKP_SERVER_IP="10.0.0.4"
BKP_SERVER_USER="caserver"
BKP_CERTS_PATH="/srv/duplicity/caserver/certificates"
ENCRYPT_KEY_ID = "master-backup-key@imovies.ch"

def backup_pkcs12(source_file_path: str, uid: str):
    """
    Perform a backup of a PKCS12 file using Duplicity.

    Parameters:
    - source_file_path (str): The path to the source PKCS12 file to be backed up.
    - uid (str): A unique identifier used in the backup filename.

    Returns:
    None

    Note:
    - The function uses Duplicity to perform the backup.
    - The backup is encrypted using the specified encryption key (ENCRYPT_KEY_ID).
    - The backup filename includes a timestamp and the provided UID.

    Dependencies:
    - Duplicity must be installed on the system.

    Environment Variables:
    - BKP_SERVER_USER: Username for the backup server.
    - BKP_SERVER_IP: IP address or hostname of the backup server.
    - BKP_CERTS_PATH: Path on the backup server where certificates are stored.
    - ENCRYPT_KEY_ID: ID of the GPG key used for encryption.

    Raises:
    - subprocess.CalledProcessError: If the Duplicity backup command fails.

    """
    assert uid != ""
    assert source_file_path != ""

    dst_file_name = f"{time.time()}_{uid}.p12"
    destination_url = f"sftp://{BKP_SERVER_USER}@{BKP_SERVER_IP}{BKP_CERTS_PATH}/{dst_file_name}"

    # Build the Duplicity command
    duplicity_command = [
        "duplicity",
        "--encrypt-key", ENCRYPT_KEY_ID,
        source_file_path,
        destination_url
    ]

    # Execute the Duplicity command
    try:
        subprocess.run(duplicity_command, check=True)
        print("Backup completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Backup failed with error: {e}")

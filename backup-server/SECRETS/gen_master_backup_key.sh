#!/bin/bash

# %no-protection: https://superuser.com/a/1360557
# https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html

# Set the key parameters
KEY_TYPE="RSA"
KEY_SIZE="2048"
KEY_EXPIRATION="0"  # Key does not expire
REAL_NAME="Master Backup Key"
EMAIL_ADDRESS="master-backup-key@imovies.ch"

# Specify the output file names
PUBLIC_KEY_FILE="backup-master-key/bkp-master-key-public.gpg"
PRIVATE_KEY_FILE="backup-master-key/bkp-master-key-private.gpg"

# Generate the GPG key pair non-interactively
gpg --batch --yes --full-generate-key <<EOF
%no-protection
Key-Type: $KEY_TYPE
Key-Length: $KEY_SIZE
Key-Usage: encrypt
Expire-Date: $KEY_EXPIRATION
Name-Real: $REAL_NAME
Name-Email: $EMAIL_ADDRESS
EOF

# Export the public key to the specified file
gpg --output "$PUBLIC_KEY_FILE" --armor --export "$EMAIL_ADDRESS"
gpg --list-packets "$PUBLIC_KEY_FILE" | grep ":user"

# Export the private key to the specified file
gpg --output "$PRIVATE_KEY_FILE" --armor --export-secret-keys "$EMAIL_ADDRESS"
gpg --list-packets "$PRIVATE_KEY_FILE" | grep ":user"

# Remove the locally generated GPG key
# Can't do in batch mode, do manually if needed
# gpg --delete-secret-keys "$EMAIL_ADDRESS"
# gpg --delete-keys "$EMAIL_ADDRESS"

# Display a message indicating successful key generation
echo "GPG key pair generated successfully."
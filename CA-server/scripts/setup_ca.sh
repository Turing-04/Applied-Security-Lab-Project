#!/bin/bash

# based on "7.5 Running a Certificate Authority", page 109 in 
# David Basin, Patrick Schaller, and Michael Schläpfer
# Applied Information Security
# – A Hands-on Approach –
# September 2023

if [ -z "$SYNCED_FOLDER" ]; then
    echo "SYNCED_FOLDER is not defined, cannot proceed!"
    exit 1
fi

CA_PATH="/etc/ssl/CA"
CA_PASSWORD_PATH="$CA_PATH/private/ca_password.txt"
CA_CERT_PATH="$CA_PATH/cacert.pem"
CA_KEY_PATH="$CA_PATH/private/cakey.pem"

#  Create the directories that hold the CA’s certificate and related files:
sudo mkdir -p "$CA_PATH"
sudo mkdir -p "$CA_PATH/certs"
sudo rm -r "$CA_PATH/newcerts" # allows tests to pass with provision on running machine
sudo mkdir -p "$CA_PATH/newcerts"
sudo mkdir -p "$CA_PATH/private"

#  The CA needs a file to keep track of the last serial number issued by the
# CA. For this purpose, create the file serial and enter the number 01 as
# the first serial number:
sudo bash -c "echo '01' > '$CA_PATH/serial'"

#  An additional file is needed to record certificates that have been issued:
sudo rm "$CA_PATH/index.txt"
sudo touch "$CA_PATH/index.txt"

# "The last file to be modified is the CA configuration file
# /etc/ssl/openssl.cnf. In the [CA_default] section of
# the file you should modify the directory entries according to the setting of
# your system. To do this, modify dir to point to /etc/ssl/CA."
# To automate this, I modify the openssl.cnf in the repo, and then overwrite the 
# default file.
sudo cat "$SYNCED_FOLDER/config/openssl.cnf" > /etc/ssl/openssl.cnf

CA_SECRETS="$SYNCED_FOLDER/SECRETS/ca-server"

# install previously generated cert and key
sudo cp "$CA_SECRETS/cakey.pem" $CA_KEY_PATH
sudo cp "$CA_SECRETS/cacert.pem" $CA_CERT_PATH

# TODO make SECRETS/ca_password.txt a file only readable by the apache web user
# this way, not any user can read it, but the flask app can
sudo cp "$CA_SECRETS/ca_password.txt" $CA_PASSWORD_PATH

# setup CRL
# see: https://jamielinux.com/docs/openssl-certificate-authority/certificate-revocation-lists.html
# First, init the crlnumber
sudo bash -c "echo '00' > '$CA_PATH/crlnumber'"
# Then, create the initial crl.pem
sudo openssl ca -config /etc/ssl/openssl.cnf -gencrl \
    -out "$CA_PATH/crl.pem" -passin file:$CA_PASSWORD_PATH


# Finally, we need to make the ca-server user own the CA dir
sudo chown --recursive ca-server "$CA_PATH"

#  recursively remove read, write, and execute permissions for the group and others 
# on all files within a directory
chmod -R u=rw,go= "$CA_PATH"
# The user needs execute permission on the directory to be able to
# list files in it
find "$CA_PATH" -type d -exec chmod u+x {} +


read_only_files=($CA_PASSWORD_PATH $CA_KEY_PATH $CA_CERT_PATH)

for file in "${read_only_files[@]}"; do
  chmod u=r,go= $file
done


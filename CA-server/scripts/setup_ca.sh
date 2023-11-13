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

#  Create the directories that hold the CA’s certificate and related files:
sudo mkdir "$CA_PATH"
sudo mkdir "$CA_PATH/certs"
sudo mkdir "$CA_PATH/newcerts"
sudo mkdir "$CA_PATH/private"

#  The CA needs a file to keep track of the last serial number issued by the
# CA. For this purpose, create the file serial and enter the number 01 as
# the first serial number:
sudo bash -c "echo '000001' > '$CA_PATH/serial'"

#  An additional file is needed to record certificates that have been issued:
sudo touch "$CA_PATH/index.txt"

# "The last file to be modified is the CA configuration file
# /etc/ssl/openssl.cnf. In the [CA_default] section of
# the file you should modify the directory entries according to the setting of
# your system. To do this, modify dir to point to /etc/ssl/CA."
# To automate this, I modify the openssl.cnf in the repo, and then overwrite the 
# default file.
sudo cat "$SYNCED_FOLDER/config/openssl.cnf" > /etc/ssl/openssl.cnf

#  At this point, create the self-signed root certificate with the command:
subj_str="/C=CH/ST=Zurich/O=iMovies/CN=iMovies root cert/emailAddress=ca-admin@imovies.ch/"
sudo openssl req -passout file:$SYNCED_FOLDER/SECRETS/ca_password.txt -new -x509 \
    -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650 \
    -subj "$subj_str"

#  Having successfully created the key and the certificate, install them into
# the correct directory:
sudo mv cakey.pem "$CA_PATH/private/"
sudo mv cacert.pem "$CA_PATH/"

# TODO make SECRETS/ca_password.txt a file only readable by the apache web user
# this way, not any user can read it, but the flask app can
sudo cp "$SYNCED_FOLDER/SECRETS/ca_password.txt" "$CA_PATH/private/ca_password.txt"
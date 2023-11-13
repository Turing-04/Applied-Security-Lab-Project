#!/bin/bash

# based on "7.5 Running a Certificate Authority", page 109 in 
# David Basin, Patrick Schaller, and Michael Schläpfer
# Applied Information Security
# – A Hands-on Approach –
# September 2023

#  Create the directories that hold the CA’s certificate and related files:
sudo mkdir /etc/ssl/CA
sudo mkdir /etc/ssl/CA/certs
sudo mkdir /etc/ssl/CA/newcerts
sudo mkdir /etc/ssl/CA/private

#  The CA needs a file to keep track of the last serial number issued by the
# CA. For this purpose, create the file serial and enter the number 01 as
# the first serial number:
sudo bash -c "echo '01' > /etc/ssl/CA/serial"

#  An additional file is needed to record certificates that have been issued:
sudo touch /etc/ssl/CA/index.txt

# TODO!!!
#  The last file to be modified is the CA configuration file
# /etc/ssl/openssl.cnf. In the [CA_default] section of
# the file you should modify the directory entries according to the setting of
# your system. To do this, modify dir to point to /etc/ssl/CA.

#  At this point, create the self-signed root certificate with the command:
subj_str="/C=CH/O=iMovies/CN=iMovies root cert/emailAddress=ca-admin@imovies.ch/"
sudo openssl req -passout file:SECRETS/ca_password.txt -new -x509 \
    -extensions v3_ca -keyout cakey.pem -out cacert.pem -days 3650 \
    -subj "$subj_str"

#  Having successfully created the key and the certificate, install them into
# the correct directory:
sudo mv cakey.pem /etc/ssl/CA/private/
sudo mv cacert.pem /etc/ssl/CA/
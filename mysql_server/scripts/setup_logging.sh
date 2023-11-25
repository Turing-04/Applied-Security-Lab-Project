#!/bin/bash

# Install syslog-ng
sudo apt install syslog-ng -y

# Set client certificate
mkdir /etc/syslog-ng/ssl
mkdir /etc/syslog-ng/ssl/certs
mkdir /etc/syslog-ng/ssl/private

# Copy certificates and set permissions
cp $SYNCED_FOLDER/SECRETS/ca-server/cacert.pem /etc/syslog-ng/ssl/certs
sudo chmod 644 /etc/syslog-ng/ssl/certs/cacert.pem

# Copy client key pair to enable client authentication
# cp $SYNCED_FOLDER/SECRETS/<client>/<client.crt> /etc/syslog-ng/ssl/certs
# sudo chmod 644 /etc/syslog-ng/ssl/certs/<client.crt>

# cp $SYNCED_FOLDER/SECRETS/<client>/<client.key> /etc/syslog-ng/ssl/private
# sudo chmod 640 /etc/syslog-ng/ssl/private/<client.key>

sudo cp $SYNCED_FOLDER/syslog-ng.conf /etc/syslog-ng
sudo systemctl restart syslog-ng
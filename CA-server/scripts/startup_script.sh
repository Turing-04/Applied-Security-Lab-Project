#!/bin/bash

export SYNCED_FOLDER="/vagrant"
CA_SERVER_ROOT="/var/www/ca-server"
CA_USER_PASSWORD="LGiiyt8pQ^f!Nyew2t2UZCX7ID^aYiXmt#gNn3#4e&P0N4mA8K"

echo "Startup script started"

# add user which runs the webserver
sudo useradd ca-server --create-home
# set his password
echo "ca-server:$CA_USER_PASSWORD" | sudo chpasswd
# allow him to run openssl without entering a password
sudo echo "ca-server ALL=NOPASSWD: /usr/bin/openssl" > /etc/sudoers.d/ca-server


# openssl CA setup
echo "Starting openssl CA setup"
bash "$SYNCED_FOLDER/scripts/setup_ca.sh"
echo "DONE: openssl CA setup"

echo "Starting install of necessary software"
# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update

# make sure we have python 3.11 and venv module
sudo apt install -y python3.11
sudo apt install -y python3.11-venv
sudo apt install -y python3-pip
# python is python 3
sudo ln -s /usr/bin/python3 /usr/bin/python

# install apache2
sudo apt install -y apache2 apache2-dev libapache2-mod-wsgi-py3
# enable wsgi for flask
sudo a2enmod wsgi

echo "Copy keys for https"
# SSLCertificateFile      /etc/ssl/certs/ca-server-https.crt
# SSLCertificateKeyFile   /etc/ssl/private/ca-server-https.key
cp "$SYNCED_FOLDER/SECRETS/ca-server-https/ca-server-https.crt" /etc/ssl/certs/ca-server-https.crt
cp "$SYNCED_FOLDER/SECRETS/ca-server-https/ca-server-https.key" /etc/ssl/private/ca-server-https.key
chown ca-server /etc/ssl/certs/ca-server-https.crt
chmod u=r,go= /etc/ssl/certs/ca-server-https.crt
# set permissions for private key
chown ca-server /etc/ssl/private/ca-server-https.key
chmod u=r,go= /etc/ssl/private/ca-server-https.key

echo "Copy ca-server-intranet crt and key"
cp "$SYNCED_FOLDER/SECRETS/ca-server-intranet/ca-server-intranet.crt" /etc/ssl/certs/ca-server-intranet.crt
cp "$SYNCED_FOLDER/SECRETS/ca-server-intranet/ca-server-intranet.key" /etc/ssl/private/ca-server-intranet.key
chown ca-server /etc/ssl/certs/ca-server-intranet.crt
chmod u=r,go= /etc/ssl/certs/ca-server-intranet.crt
# set permissions for private key
chown ca-server /etc/ssl/private/ca-server-intranet.key
chmod u=r,go= /etc/ssl/private/ca-server-intranet.key

echo "Copy apache2 config file"
cp "$SYNCED_FOLDER/config/ca-server.conf" /etc/apache2/sites-available/
cp "$SYNCED_FOLDER/config/apache2.conf" /etc/apache2/apache2.conf
cp "$SYNCED_FOLDER/config/envvars" /etc/apache2/envvars

echo "Copy src to $CA_SERVER_ROOT"
mkdir -p "$CA_SERVER_ROOT"
cp -r "$SYNCED_FOLDER/src/" "$CA_SERVER_ROOT/"
rm -r "$CA_SERVER_ROOT/src/__pycache__" "$CA_SERVER_ROOT/src/.venv"
cp "$SYNCED_FOLDER/scripts/startup_server.sh" "$CA_SERVER_ROOT"

sudo chown --recursive ca-server "$CA_SERVER_ROOT"

sudo chmod u+x "$CA_SERVER_ROOT/startup_server.sh"
sudo -u ca-server "$CA_SERVER_ROOT/startup_server.sh"

sudo a2enmod ssl
sudo systemctl restart apache2
echo "Check apache config file for errors"
sudo apachectl configtest
sudo a2ensite ca-server
sudo systemctl restart apache2

# Check if server is up
wget --no-check-certificate -O - https://localhost:443/ping

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
# TODO delete command history
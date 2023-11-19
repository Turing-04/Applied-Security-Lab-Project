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
sudo echo "ca-server ALL=(ALL) NOPASSWD: /usr/bin/openssl" > /etc/sudoers.d/ca-server


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
# TODO enable
# sudo apt install -y apache2 apache-dev

echo "Copy src to $CA_SERVER_ROOT"
mkdir -p "$CA_SERVER_ROOT"
cp -r "$SYNCED_FOLDER/src/" "$CA_SERVER_ROOT/"
rm -r "$CA_SERVER_ROOT/src/__pycache__" "$CA_SERVER_ROOT/src/.venv"
cp "$SYNCED_FOLDER/scripts/startup_server.sh" "$CA_SERVER_ROOT"

sudo chown --recursive ca-server "$CA_SERVER_ROOT"

# Grant execute permission for ca sign script to ca-server user
sudo chmod u+x "$CA_SERVER_ROOT/src/ca_sign_csr.sh"

sudo chmod u+x "$CA_SERVER_ROOT/startup_server.sh"
sudo -u ca-server "$CA_SERVER_ROOT/startup_server.sh"

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
# TODO delete command history
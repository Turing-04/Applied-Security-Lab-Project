#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

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

echo "Copy src to $VAGRANT_HOME"
cp -r "$SYNCED_FOLDER/src/" "$VAGRANT_HOME/"
rm -r "$VAGRANT_HOME/src/__pycache__" "$VAGRANT_HOME/src/.venv"

# TODO !!! grant only execute to apache user
chmod +x "$VAGRANT_HOME/src/ca_sign_csr.sh"

cd "$VAGRANT_HOME/src"
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

# performing unit tests
python -m pytest

# TODO allow apache user to run ca_sign_csr.sh as sudo without entering password
# add file to /etc/sudoers.d/ with:
# www-data ALL=(ALL) NOPASSWD: /path/to/your/script.sh
# see https://www.digitalocean.com/community/tutorials/how-to-edit-the-sudoers-file

# TODO set static ip to new network interface
# 10.0.0.3

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
# TODO delete command history
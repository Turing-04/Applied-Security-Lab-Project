#!/bin/bash

SYNCED_FOLDER="/vagrant"
cd $SYNCED_FOLDER

echo "Startup script started"

# openssl CA setup
echo "Starting openssl CA setup"
bash scripts/setup_ca.sh

# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update

# make sure we have python 3.11 and venv module
sudo apt install -y python3.11
sudo apt install -y python3.11-venv
sudo apt install -y python3-pip
# python is python 3
sudo ln -s /usr/bin/python3 /usr/bin/python

python -m venv src/.venv
source src/.venv/bin/activate
pip install -r src/requirements.txt

# performing unit tests
pytest src

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

echo "Starting install of necessary software"
# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update

# install duplicity
sudo apt install duplicity -y 

# copy backup private key for ssh connection to ~/.ssh
cp $SYNCED_FOLDER/../SECRETS/backup-server/backup-server.key /home/.ssh/backup-server.key
cp $SYNCED_FOLDER/../SECRETS/


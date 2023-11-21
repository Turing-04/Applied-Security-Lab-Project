#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

echo "Starting install of necessary software"
# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update

# install duplicity
sudo apt install duplicity -y 

# TODO copy backup private key for ssh connection to ~/.ssh
cp $SYNCED_FOLDER/SECRETS/backup-server/backup-server.key /home/.ssh/backup-server.key
cp $SYNCED_FOLDER/SECRETS/backup-server/backup-server.pgp /home/.gnupg/duplicity.pgp

# TODO copy public key to client machines for backing up

# prepare backup directory
mkdir -p /srv/duplicity/webserver /srv/duplicity/caserver /srv/duplicity/mysql

# run backup setup script
echo "start backup server cron setup"
# create dedicated backup scripts directory
mkdir -p /etc/duplicity/scripts
# copy backup setup script to above dir
cp $SYNCED_FOLDER/scripts/backup_setup.sh /etc/duplicity/scripts/backup_setup.sh
chmod +x /etc/duplicity/scripts/backup_setup.sh

# run backup cron job setup
bash "$SYNCED_FOLDER/scripts/cron_setup_backup.sh"
echo "done backup server cron setup"


#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

echo "Starting to install necessary software"
# system updadte
sudo apt update

# install duplicity
sudo apt install duplicity -y 

# create backup user and add backup to sudoers group
sudo useradd -m backupusr -p go41QYHlCEIvoOlc54

# create /home/backup directory and set permissions
mkdir -p /home/backup/.ssh /home/backup/.gnupg
sudo chown -R backupusr:backupusr /home/backup

# TODO copy backup private key for ssh connection to /.ssh
# cp $SYNCED_FOLDER/SECRETS/backup-server/backup-server.key /home/backup/.ssh/backup-server.key
# cp $SYNCED_FOLDER/SECRETS/backup-server/backup-server.pgp /home/backup/.gnupg/duplicity.pgp
mkdir -p /home/backup/.ssh && cp $SYNCED_FOLDER/SECRETS/authorized_keys /home/root/.ssh/authorized_keys
sudo chmod -R go=/home/backup/.ssh
sudo chmod -R go-rwx /home/backup/.gnupg

# prepare backup directory
mkdir -p /srv/duplicity/webserver /srv/duplicity/caserver /srv/duplicity/mysql
sudo chown -R backupusr:backupusr /srv/duplicity

# set up client agent backup - server cron job is no longer needed
# # run backup setup script
# echo "start backup server cron setup"
# # create dedicated backup scripts directory
# mkdir -p /etc/duplicity/scripts
# # copy backup setup script to above dir
# cp $SYNCED_FOLDER/scripts/backup_setup.sh /etc/duplicity/scripts/backup_setup.sh
# chmod +x /etc/duplicity/scripts/backup_setup.sh

# # run backup cron job setup
# bash "$SYNCED_FOLDER/scripts/cron_setup_backup.sh"
# echo "done backup server cron setup"


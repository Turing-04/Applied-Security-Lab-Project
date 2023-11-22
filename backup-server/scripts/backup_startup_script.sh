#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

echo "Starting to install necessary software"
# system updadte
sudo apt update

# install duplicity
sudo apt install duplicity -y 

# Step 1: create users and automatically their home directory
#--------------------------------------------
echo "creating users and home directories..."
# create backup user 
sudo useradd -m backupusr -p TmikweJoB7tVpobBcT
mkdir -p /home/backupusr/.ssh
sudo chmod 700 /home/backupusr/.ssh

# create caserver user
sudo useradd -m caserver -p TUsZNJZR4Nlx9Du1nN
mkdir -p /home/caserver/.ssh && sudo chmod 700 /home/caserver/.ssh
touch /home/caserver/.ssh/authorized_keys && sudo chmod 600 /home/caserver/.ssh/authorized_keys

# create webserver user
sudo useradd -m webserver -p dFP9s2ohTsCSXBHTmt
mkdir -p /home/webserver/.ssh && sudo chmod 700 /home/webserver/.ssh
touch /home/webserver/.ssh/authorized_keys && sudo chmod 600 /home/webserver/.ssh/authorized_keys

# create mysql user
sudo useradd -m mysql -p bUDvwzw5cVaETMBrIo
mkdir -p /home/mysql/.ssh && sudo chmod 700 /home/mysql/.ssh
touch /home/mysql/.ssh/authorized_keys && sudo chmod 600 /home/mysql/.ssh/authorized_keys

# create sysadmin user and add sysadmin to sudo group
sudo useradd -m sysadmin -p RbNoH9BGxO1FcyTXc1
sudo usermod -aG sudo sysadmin
mkdir -p /home/sysadmin/.ssh && sudo chmod 700 /home/sysadmin/.ssh
touch /home/sysadmin/.ssh/authorized_keys && sudo chmod 600 /home/sysadmin/.ssh/authorized_keys

# Step 2: copy public keys to authorized_keys files
#--------------------------------------------
# caserver

# webserver

# mysql

# sysadmin

# Step 3: configure sshd for uni-directional ssh connection: only from clients to backup server
#--------------------------------------------


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

# set up sshd with unidirectional key authentication

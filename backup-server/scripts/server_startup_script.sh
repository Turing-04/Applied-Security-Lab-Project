#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

sudo apt update
sudo apt upgrade -y

# CREATE USERS
echo "Starting create_users setup"
bash "$SYNCED_FOLDER/scripts/setup_users.sh"
echo "DONE: create_users setup"

# SSHD SETUP
echo "Starting ssh setup"
bash "$SYNCED_FOLDER/scripts/setup_ssh.sh"
echo "DONE: ssh setup"

# BACKUP SETUP
echo "Starting backup setup"
bash "$SYNCED_FOLDER/scripts/setup_backup.sh"
echo "DONE: backup setup"

# LOGGING SETUP
echo "Starting logging setup"
bash "$SYNCED_FOLDER/scripts/setup_logging.sh"
echo "DONE: logging setup"

# ROUTER SET UP 
echo "Starting router setup"
bash "$SYNCED_FOLDER/scripts/router_setup.sh"
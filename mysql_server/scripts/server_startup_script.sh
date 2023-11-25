#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

sudo apt update
sudo apt upgrade -y

# users setup
echo "Starting user setup"
bash "$SYNCED_FOLDER/scripts/setup_user.sh"
echo "DONE: user setup"

# ssh setup
echo "Starting ssh setup"
bash "$SYNCED_FOLDER/scripts/setup_ssh.sh"
echo "DONE: ssh setup"

# mysql  setup
echo "Starting mysql setup"
bash "$SYNCED_FOLDER/scripts/setup_mysql.sh"
echo "DONE: mysql setup"

# backup setup
echo "Starting mysql backup setup"
bash "$SYNCED_FOLDER/scripts/setup_backup.sh"
echo "DONE: backup setup"

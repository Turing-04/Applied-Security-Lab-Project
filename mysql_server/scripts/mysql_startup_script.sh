#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

# mysql server setup
echo "Starting mysql setup"
bash "$SYNCED_FOLDER/scripts/setup_mysql.sh"
echo "DONE: mysql setup"

# mysql backup setup
echo "Starting mysql backup setup"
bash "$SYNCED_FOLDER/scripts/setup_backup.sh"


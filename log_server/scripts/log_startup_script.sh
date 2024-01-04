#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

# mysql server setup
echo "Starting log_server setup"
bash "$SYNCED_FOLDER/scripts/setup_log_server.sh"
echo "DONE: log_server setup"


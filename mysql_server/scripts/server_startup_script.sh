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

# logging setup
echo "Starting logging setup"
bash "$SYNCED_FOLDER/scripts/setup_logging.sh"
echo "DONE: logging setup"

# backup setup
echo "Starting backup setup"
bash "$SYNCED_FOLDER/scripts/setup_backup.sh"
echo "DONE: backup setup"

# router setup
echo "Starting router setup"
bash "$SYNCED_FOLDER/scripts/setup_router.sh"
echo "DONE: router setup"

# cron job of mysql databaselogical backup 

# copy mysql backup script
cp $SYNCED_FOLDER/scripts/backup_mysql.sh /home/backupusr/scripts/backup_mysql.sh
chown backupusr:backupusr /home/backupusr/scripts/backup_mysql.sh
chmod 700 /home/backupusr/scripts/backup_mysql.sh


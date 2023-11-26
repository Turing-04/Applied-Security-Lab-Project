#!/bin/bash

# Prepare backup directory
#--------------------------------------------
echo "preparing backup directory..."

# create router directory and set permissions
mkdir -p /backup/router/config /backup/router/logs

sudo chown -R router:router /backup/router/config
sudo chmod 700 /backup/router/config

sudo chown -R router:router /backup/router/logs
sudo chmod 700 /backup/router/logs

# create webserver directory and set permissions
mkdir -p /backup/webserver/config /backup/webserver/logs

sudo chown -R webserver:webserver /backup/webserver/config
sudo chmod 700 /backup/webserver/config

sudo chown -R webserver:webserver /backup/webserver/logs
sudo chmod 700 /backup/webserver/logs

# create caserver directory and set permissions
mkdir -p /backup/caserver/config /backup/caserver/logs /backup/caserver/internal_database /backup/caserver/keys_certs /backup/caserver/logs

sudo chown -R caserver:caserver /backup/caserver/config
sudo chmod 700 /backup/caserver/config

sudo chown -R caserver:caserver /backup/caserver/internal_database
sudo chmod 700 /backup/caserver/internal_database

sudo chown -R caserver:caserver /backup/caserver/keys_certs
sudo chmod 700 /backup/caserver/keys_certs

sudo chown -R caserver:caserver /backup/caserver/logs
sudo chmod 700 /backup/caserver/logs


# create mysql directory and set permissions
mkdir -p /backup/mysql/config /backup/mysql/mariadb /backup/mysql/logs

sudo chown -R mysql:mysql /backup/mysql/config
sudo chmod 700 /backup/mysql/config

sudo chown -R mysql:mysql /backup/mysql/mariadb
sudo chmod 700 /backup/mysql/mariadb

sudo chown -R mysql:mysql /backup/mysql/logs
sudo chmod 700 /backup/mysql/logs

# create backupsrv directory and set permissions
mkdir -p /backup/backupsrv/config /backup/backupsrv/logs

sudo chown -R backupusr:backupusr /backup/backupsrv/config
sudo chmod 700 /backup/backupsrv/config

sudo chown -R backupusr:backupusr /backup/backupsrv/logs
sudo chmod 700 /backup/backupsrv/logs



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


#--------------------------------------------
# check logging for backup server
# /var/log/auth.log
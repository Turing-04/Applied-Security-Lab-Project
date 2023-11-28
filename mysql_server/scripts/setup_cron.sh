#!/bin/bash

# BACKUP MYSQL DATABASE
#--------------------------------------------
# copy mysql backup script
cp $SYNCED_FOLDER/scripts/backup_mysql.sh /home/backupusr/scripts/backup_mysql.sh
chown backupusr:backupusr /home/backupusr/scripts/backup_mysql.sh
chmod 700 /home/backupusr/scripts/backup_mysql.sh

# backup mysql script
SCRIPT="/home/backupusr/scripts/backup_mysql.sh"

# cron job schedule
SCHEDULE="45 22 * * *"

# add cron job
(crontab -l 2>/dev/null; echo "$SCHEDULE $SCRIPT") | crontab -

# BACKUP MYSQL SERVER CONFIG
#--------------------------------------------
# copy mysql server config backup script
cp $SYNCED_FOLDER/scripts/backup_mysqlconfig.sh /home/backupusr/scripts/backup_mysqlconfig.sh
chown backupusr:backupusr /home/backupusr/scripts/backup_mysqlconfig.sh
chmod 700 /home/backupusr/scripts/backup_mysqlconfig.sh

# add backup mysql config files cron job
(crontab -l 2>/dev/null; echo "15 11 * * * /home/backupusr/scripts/backup_mysqlconfig.sh") | crontab -
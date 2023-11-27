#!/bin/bash

# create database logical backup dump
echo "starting to create mysql logical backup >>>"
mysqldump --databases imovies -uroot -pH6Mue92MeNNnvFRpJ67V > /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chown backupusr:backupusr /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chmod 600 /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
echo "finishing creating mysql logical backup..."

# switch user
# echo "change backupuser profile again???"
su backupusr<<REALEND
# sftp command
echo "starting sftp >>>"
sftp -o StrictHostKeyChecking=no backupserver:/backup/mysql/mariadb <<EOF
cd /backup/mysql/mariadb
put /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
EOF
echo "finishing sftp file transfer..."
REALEND

exit


# # variables
# echo "setting up variables >>>"
# REMOTE_USER='mysql'
# REMOTE_HOST='10.0.0.4'
# HOST_NAME='backupserver'
# REMOTE_DIR='/backup/mysql/mariadb'
# LOCAL_FILE_PATH=/home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
# echo "finishing setting up variables..."
## sftp how to use
# sftp $HOST_NAME:$REMOTE_DIR <<EOF
# cd $REMOTE_DIR
# put #LOCAL_FILE_PATH
# EOFÍ
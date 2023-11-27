#!/bin/bash

# switch user
su backupusr

# create database logical backup dump
mysqldump --databases imovies -uroot -pH6Mue92MeNNnvFRpJ67V > /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chown backupusr:backupusr /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chmod 600 /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql


# variables
HOST_NAME='backupserver'
REMOTE_DIR='/backup/mysql/mariadb'
LOCAL_FILE_PATH=/home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql

# sftp command
sftp $HOST_NAME:$REMOTE_DIR <<EOF
cd $REMOTE_DIR
put $LOCAL_FILE_PATH
EOF

exit

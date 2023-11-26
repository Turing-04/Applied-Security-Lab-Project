#!/bin/bash

# create database logical backup dump
mysqldump --database imovies -uroot -pH6Mue92MeNNnvFRpJ67V > /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chown backupusr:backupusr /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chmod 600 /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql


# backup with sftp
su backupusr

# variables
ROMOTE_USER='mysql'
REMOTE_HOST='10.0.0.4'
REMOTE_DIR='/backup/mysql/mariadb'
LOCAL_FILE_PATH='/home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql'

# sftp command
sftp $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR <<EOF
cd $REMOTE_DIR
put $LOCAL_FILE_PATH
EOF


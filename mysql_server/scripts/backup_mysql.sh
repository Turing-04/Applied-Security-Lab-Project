#!/bin/bash

# create database logical backup dump
echo "starting to create mysql logical backup >>>"
mysqldump --databases imovies -uroot -pH6Mue92MeNNnvFRpJ67V > /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chown backupusr:backupusr /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chmod 600 /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
echo "finishing creating mysql logical backup..."

# remove the former day copy: rotate old copy to offline storage
rm /home/backupusr/mysql/imovies-$(date -d 'yesterday' '+%Y-%m-%d').sql

# switch user
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

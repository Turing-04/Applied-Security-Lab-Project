#!/bin/bash

# create backup storage in backupusr home directory and set permission
mkdir /home/backupusr/mysql
chown backupusr:backupusr /home/backupusr/mysql
chmod 700 /home/backupusr/mysql

# create database logical backup dump
mysqldump --database imovies -uroot -pH6Mue92MeNNnvFRpJ67V > /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chown backupusr:backupusr /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql
chmod 600 /home/backupusr/mysql/imovies-$(date '+%Y-%m-%d').sql


# backup with sftp
su -u backupusr

duplicity /etc/mysql/ sftp://mysql@10.0.0.4//backup/mysql/mariadb/


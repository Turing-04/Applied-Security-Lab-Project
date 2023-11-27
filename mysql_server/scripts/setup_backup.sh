#!/bin/bash

# create backup storage in backupusr home directory and set permission
mkdir /home/backupusr/mysql
chown backupusr:backupusr /home/backupusr/mysql
chmod 700 /home/backupusr/mysql

mkdir /home/backupusr/scripts
chown backupusr:backupusr /home/backupusr/scripts
chmod 700 /home/backupusr/scripts


#!/bin/bash

# install duplicity
sudo apt install duplicity -y

# 9.2 Create backupusr user and set up permission
sudo useradd -m backupusr -p vzO107Z4icPL15VhmB
mkdir -p /home/backupusr/.ssh
sudo chmod 700 /home/backupusr/.ssh
touch /home/backupusr/.ssh/config && echo "Host 10.0.0.4" >> /home/backupusr/.ssh/config
echo "IdentityFile /home/backupusr/.ssh/mysql-server.key" >> /home/backupusr/.ssh/config
# Copy private key for ssh connection
cp $SYNCED_FOLDER/SECRETS/mysql-server-ssh/mysql-server-ssh /home/backupusr/.ssh/mysql-server-ssh
sudo chmod 600 /home/backupusr/.ssh/mysql-server-ssh
sudo chown -R backupusr:backupusr /home/backupusr/.ssh

# backup with duplicity

su -u backupusr

duplicity /etc/mysql/ sftp://mysql@10.0.0.4//backup/mysql/mariadb/


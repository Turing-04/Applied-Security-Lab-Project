#!/bin/bash

# install duplicity
sudo apt install duplicity -y

# backup with duplicity
su -u backupusr

duplicity /etc/mysql/ sftp://mysql@10.0.0.4//backup/mysql/mariadb/


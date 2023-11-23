#!/bin/bash

# client backup script using duplicity

# install packages
sudo apt update
sudo apt install duplicity -y

# configure duplicity for backup
#--------------------------------------------
user=$(whoami)

# backup directory triage
# TODO: update source directories
if [ "$user" = "caserver" ]; then
    duplicity full --ssh-options "-oIdentifyFile=/home/backupusr/.ssh/backup-server.key" /path/to/certificates/ sftp://caserver@10.0.0.4//srv/duplicity/caserver/
elif [ "$user" = "mysql" ]; then
    duplicity --ssh-options "-oIdentifyFile=/home/backupusr/.ssh/backup-server.key" /path/to/mysql/ sftp://mysql@10.0.0.4//srv/duplicity/mysql/
else
    echo "user not found for duplicity backup."
fi




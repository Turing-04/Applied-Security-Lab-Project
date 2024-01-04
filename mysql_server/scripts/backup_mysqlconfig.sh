#!/bin/bash

# switch user
su backupusr<<REALEND
# sftp command
echo "starting sftp >>>"
sftp -o StrictHostKeyChecking=no backupserver:/backup/mysql/config <<EOF
cd /backup/mysql/config
put /etc/ssh/sshd_config 
put -r /etc/ssh/sshd_config.d 
put /etc/mysql/mariadb.cnf 
put -r /etc/mysql/mariadb.conf.d 
rename /backup/mysql/config/sshd_config /backup/mysql/config/sshd_config-$(date '+%Y-%m-%d')
rename /backup/mysql/config/sshd_config.d /backup/mysql/config/sshd_config-$(date '+%Y-%m-%d').d
rename /backup/mysql/config/mariadb.cnf /backup/mysql/config/mariadb-$(date '+%Y-%m-%d').cnf
rename /backup/mysql/config/mariadb.conf.d /backup/mysql/config/mariadb-$(date '+%Y-%m-%d').conf.d
EOF
echo "finishing sftp file transfer..."
REALEND

exit
#!/bin/bash

# switch user
su backupusr<<REALEND
# sftp command
echo "starting sftp >>>"
sftp -o StrictHostKeyChecking=no backupserver:/backup/mysql/config <<EOF
cd /backup/mysql/config
put /etc/ssh/sshd_config 
put /etc/ssh/sshd_config.d 
put /etc/mysql/mariadb.cnf 
put /etc/mysql/mariadb.conf.d 
put/etc/ssl/openssl.cnf
mv /backup/mysql/config/sshd_config /backup/mysql/config/sshd_config-$(date '+%Y-%m-%d')
mv /backup/mysql/config/sshd_config.d /backup/mysql/config/sshd_config-$(date '+%Y-%m-%d').d
mv /backup/mysql/config/mariadb.cnf /backup/mysql/config/mariadb-$(date '+%Y-%m-%d').cnf
mv /backup/mysql/config/mariadb.conf.d /backup/mysql/config/mariadb-$(date '+%Y-%m-%d').conf.d
mv /backup/mysql/config/openssl.cnf /backup/mysql/config/openssl-$(date '+%Y-%m-%d').cnf
EOF
echo "finishing sftp file transfer..."
REALEND

exit
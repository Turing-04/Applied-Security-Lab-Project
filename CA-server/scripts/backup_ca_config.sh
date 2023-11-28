#!/bin/bash

# switch user
su ca-server<<REALEND
# sftp command
echo "starting sftp >>>"
sftp -o StrictHostKeyChecking=no 10.0.0.4:/backup/caserver/config <<EOF
cd /backup/caserver/config
put /etc/ssh/sshd_config 
put -r /etc/ssh/sshd_config.d 
put -r /var/www/ca-server/
put -r /etc/apache2/
put /etc/ssl/CA/index.txt
put /etc/ssl/CA/crl.pem
put /etc/ssl/CA/serial
put /etc/ssl/CA/crlnumber
put /etc/ssl/openssl.cnf
put /etc/syslog-ng/syslog-ng.conf
EOF
echo "finishing sftp file transfer..."
REALEND

exit
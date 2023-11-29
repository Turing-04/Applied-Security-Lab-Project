#!/bin/bash

# switch user
su backupusr<<REALEND
# sftp command
echo "starting sftp >>>"
sftp -o StrictHostKeyChecking=no backupserver:/backup/webserver/config <<EOF
cd /backup/webserver/config
put /etc/ssh/sshd_config 
put /etc/syslog-ng/syslog-ng.conf
put -r /etc/ssh/sshd_config.d 
put -r /etc/apache2/
mkdir -p webserver
cd webserver
put /var/www/webserver/app/*.py
put /var/www/webserver/app/*.wsgi
put /var/www/webserver/app/*.txt
put -r /var/www/webserver/app/static
put -r /var/www/webserver/app/templates 
EOF
echo "finishing sftp file transfer..."
REALEND

exit
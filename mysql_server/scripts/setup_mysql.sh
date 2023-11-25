#!/bin/bash

sudo apt update
sudo apt upgrade -y

# 1. Install MariaDB
sudo apt install mariadb-server -y
mysql_secure_installation <<EOF

n
y
root
root
y
y
y
y
EOF

# 2. Create database and load data
mysql -u root -proot -e "CREATE DATABASE imovies;"

# [TODO] Think about the schema to remove vulneratibilities
mysql -u root -proot imovies < $SYNCED_FOLDER/imovies_users.db

# 3. Create certificates table
mysql -u root -proot imovies -e "CREATE TABLE certificates (uid varchar(64) NOT NULL, certificate varchar(6000), PRIMARY KEY (uid));"
mysql -u root -proot imovies -e "INSERT INTO certificates (uid) SELECT uid FROM users;"

# 4. Create users in MySQL and set privileges
# webserver with read/write access to table "users" and read access to table "certificate";
# caserver with read/write access to the "certificates" table.
# [TODO] update ip address of web server
mysql -u root -proot imovies -e "CREATE USER 'webserver'@'%' IDENTIFIED BY '}DqG3mZ8neKPp?#Uc?49K&W2' REQUIRE X509;"
mysql -u root -proot imovies -e "GRANT SELECT, INSERT, UPDATE, DELETE ON users TO 'webserver'@'%';"
mysql -u root -proot imovies -e "GRANT SELECT ON certificates TO 'webserver'@'%';"

mysql -u root -proot imovies -e "CREATE USER 'caserver'@'10.0.0.3' IDENTIFIED BY 'cn9@1kbka;}=(iPgEMO1&{XW' REQUIRE X509;"
mysql -u root -proot imovies -e "GRANT SELECT, INSERT, UPDATE, DELETE ON certificates TO 'caserver'@'10.0.0.3';"

mysql -u root -proot -e "FLUSH PRIVILEGES;"

# 5. Change password for the root user
mysql -u root -proot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'H6Mue92MeNNnvFRpJ67V';"

# 6. Change bind-address from localhost to the interface in the configuration file.
sudo sed -i "s/.*bind-address.*/bind-address = 10.0.0.5/" /etc/mysql/mariadb.conf.d/50-server.cnf

# 7. Enable TLS in mariadb
# 7.1 Create folders for certs and keys
mkdir /etc/mysql/ssl
mkdir /etc/mysql/ssl/certs
mkdir /etc/mysql/ssl/private

# 7.2 Copy certificates and set permissions
cp $SYNCED_FOLDER/SECRETS/mysql-server/mysql-server.crt /etc/mysql/ssl/certs
cp $SYNCED_FOLDER/SECRETS/ca-server/cacert.pem /etc/mysql/ssl/certs
sudo chmod 644 /etc/mysql/ssl/certs/mysql-server.crt /etc/mysql/ssl/certs/cacert.pem

cp $SYNCED_FOLDER/SECRETS/mysql-server/mysql-server.key /etc/mysql/ssl/private
sudo chmod 640 /etc/mysql/ssl/private/mysql-server.key
sudo chown root:mysql /etc/mysql/ssl/private/mysql-server.key

# 7.3 Set TLS configuration in MariaDB
cp $SYNCED_FOLDER/mariadb-server-tls.cnf /etc/mysql/mariadb.conf.d

# 8. Restart mysql
sudo systemctl restart mariadb

# 7.4 [TODO on WEBSERVER and CASERVER] Set Client certificate authentication on the client machine
# To enable client authentication, parameters below should be set in the clients:

#ssl_cert = /etc/my.cnf.d/certificates/client-cert.pem
#ssl_key = /etc/my.cnf.d/certificates/client-key.pem
#ssl_ca = /etc/my.cnf.d/certificates/ca.pem

# 7.5 Enable server authentication om the client side
#ssl-verify-server-cert

# 9. Create sysadmin user and add it to the sudoers group
sudo useradd -m sysadmin -p dv8RCJruycKGyN
sudo usermod -aG sudo sysadmin

# 9.2 Create backupusr user and set up permission
sudo useradd -m backupusr -p vzO107Z4icPL15VhmB
mkdir -p /home/backupusr/.ssh
sudo chmod 700 /home/backupusr/.ssh
touch /home/backupusr/.ssh/config && echo "IdentityFile /home/backupusr/.ssh/mysql-server.key" >> /home/backupusr/.ssh/config
# Copy private key for ssh connection
cp $SYNCED_FOLDER/SECRETS/mysql-server/mysql-server.key /home/backupusr/.ssh/mysql-server.key
sudo chmod 600 /home/backupusr/.ssh/mysql-server.key
sudo chown -R backupusr:backupusr /home/backupusr/.ssh

# 10. Set SSH configuration on the server

# 10.1 In sysadmin home: create SSH folder for public keys 
mkdir -p /home/sysadmin/.ssh && touch /home/sysadmin/.ssh/authorized_keys

# 10.2 Copy sysadmin public key and set correct permissions
ssh-keygen -f $SYNCED_FOLDER/sysadmin-ssh.pub -i -m PKCS8 &>  /home/sysadmin/.ssh/authorized_keys
sudo chmod -R go= /home/sysadmin/.ssh
sudo chown -R sysadmin:sysadmin /home/sysadmin/.ssh

# 10.3 Disable PermitRootLogin in /etc/ssh/sshd_config
sudo sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config

# 10.4 Allow PubkeyAuthentication in /etc/ssh/sshd_config
sudo sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/" /etc/ssh/sshd_config

# 10.5 Allow only sysadmin host to ssh to the machine
sudo echo "AllowUsers sysadmin" >> /etc/ssh/sshd_config

# 10.6 Restart sshd
sudo systemctl restart sshd

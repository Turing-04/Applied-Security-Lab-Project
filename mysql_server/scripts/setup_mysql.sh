#!/bin/bash

sudo apt update
sudo apt upgrade -y

# 1. Install MariaDB: https://linuxgenie.net/how-to-install-mariadb-on-debian-12-bookworm-distribution/
# Notes: remove remote connection to root, only localhost, add the root password during the isntallation process.
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

# 2.Login into mysql: https://www.digitalocean.com/community/tutorials/how-to-import-and-export-databases-in-mysql-or-mariadb#step-2-mdash-importing-a-mysql-or-mariadb-database
mysql -u root -proot -e "CREATE DATABASE imovies;"

# 3. Create database and load data
# Think about the schema to remove vulneratibilities
mysql -u root -proot imovies < $SYNCED_FOLDER/imovies_users.db

# 4. Create certificates table
mysql -u root -proot imovies -e "CREATE TABLE certificates (uid varchar(64) NOT NULL, certificate varchar(6000) NOT NULL, expire_timestamp timestamp  NOT NULL, revoke_timestamp timestamp);"

# 5. Create users in MySQL and set privileges
# webserver with read/write access to table "users" and read access to table "certificate";
# caserver with read/write access to the "certificates" table.
# [TODO] update ip address by replacing '%' in the following code
mysql -u root -proot imovies -e "CREATE USER 'webserver'@'%' IDENTIFIED BY 'webserver123';"
mysql -u root -proot imovies -e "GRANT SELECT, INSERT, UPDATE, DELETE ON users TO 'webserver'@'%';"
mysql -u root -proot imovies  -e "GRANT SELECT ON certificates TO 'webserver'@'%';"

mysql -u root -proot imovies -e "CREAT USERS, 'caserver'@'%' IDENTIFIED BY 'caserver123';"
mysql -u root -proot imovies -e "GRANT SELEECT, INSERT, UPDATE, DELETE ON certificates TO 'caserver'@'%';"

mysql -u root -proot imovies -e "FLUSH PRIVILEGES;"

# 6. [TODO] change bind-address from localhost to the interface in the configuration file.

# 7. [TODO] enable TLS in mariadb

# 8. Create sysadmin user and add it to the sudoers group
# 8.1. create user and set the password:
sudo useradd -m sysadmin -p dv8RCJruycKGyN

# 8.2. add user to the sudo group
sudo usermod -aG sudo sysadmin

# 9. [TO CHECK ON THE MACHINE] Set ssh connection bettween the client and the server
# COPY NECESSARY KEYS
# 9.4. Disable PasswordAuthentication in /etc/ssh/sshd_config
# vim /etc/ssh/sshd_config; PasswordAuthentication no;

# 9.5. Allow only sysadmin host to ssh to the machine
# vim /etc/ssh/sshd_config; AllowUsers   sysadmin

# 9.6. Disable PermitRootLogin:
# vim /etc/ssh/sshd_config; PermitRootLogin no;

# 9.7. Restart sshd on the server: 
# sudo systemctl restart ssh

# 9.8. [EXTRA STEP] it might be unnecessary but we can set up /etc/hosts.allow and deny to allow only internal IPs to ssh.
# here is how: https://docs.rackspace.com/docs/restrict-ssh-login-to-a-specific-ip-or-host


#!/bin/bash

# export SYNCED_FOLDER="/vagrant"

sudo apt update
sudo apt upgrade -y

# MySQL dows not work properly on debian bookworm
# install mysql
# cd /tmp/
# wget https://dev.mysql.com/get/mysql-apt-config_0.8.25-1_all.deb
# apt install ./mysql-apt-config_0.8.25-1_all.deb
# debian bullsye, mysql-8.0, OK, OK
# apt update
# apt install mysql-server

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


# To add the password for the user (out of installation process), example for root: 
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'
# flush privileges;
# exit;

# 3. Create database and load data
# Think about the schema to remove vulneratibilities

# Exit mysql and copy imovies.db to tmp folder (using Shared folder feature in Virtual Box) and import it in MariaDB
mysql -u root -proot imovies < $SYNCED_FOLDER/imovies_users.db

# How often to do the backup? What happends on the password change (if no backup)? SHhoud system administrator be in charge?

# 4. Create certificates table
mysql -u root -proot imovies -e "CREATE TABLE certificates (uid varchar(64) NOT NULL, certificate varchar(6000) NOT NULL, expire_timestamp timestamp  NOT NULL, revoke_timestamp timestamp);"


# we checked the types, etc of tables users, to confirm:
# SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.Columns where table_name="users";
# update column datatype by:
# ALTER table MODIFY COLUMN column_name desired_datatype;


# 5. Create users in MySQL and set privileges
# two users: webserver with read/write access to table "users" and read access to table "certificate"; and caserver with read/write access to the "certificates" table.
# the above two users are remote users, for security TODO update ip address by replacing '%' in the following code
mysql -u root -proot imovies -e "CREATE USER 'webserver'@'%' IDENTIFIED BY 'webserver123';"
mysql -u root -proot imovies -e "GRANT SELECT, INSERT, UPDATE, DELETE ON users TO 'webserver'@'%';"
mysql -u root -proot imovies  -e "GRANT SELECT ON certificates TO 'webserver'@'%';"

mysql -u root -proot imovies -e "CREAT USERS, 'caserver'@'%' IDENTIFIED BY 'caserver123';"
mysql -u root -proot imovies -e "GRANT SELEECT, INSERT, UPDATE, DELETE ON certificates TO 'caserver'@'%';"

mysql -u root -proot imovies -e "FLUSH PRIVILEGES;"

# configure mysql to accept remote connections:
# edit the MySQL configuration file in /etc/mysql/. 
# look for the line that says 'bind-address = 127.0.0.1', and change it to 'bind-address=0.0.0.0' to allow connections from any IP
# or to specific IP address to the server, with multiple addresses separated by ','.

# ensure that tthe firewall on the MySQL server allows incoming connections on the MySQL port (default 3306).

# TODO___test the new users from remote machines___TODO
# mysql -h [mysql_server_ip] -u caserver -p

# 6. [TO CHECK ON THE MACHINE] Create sysadmin user and add it to the sudoers group
# 6.1. create user and set the password:
sudo adduser sysadmin

# 6.2. add user to the sudo group
sudo usermod -aG sudo sysadmin

# 6.3. to verify two options:
# getent group sudo 
# id <username>

# 7. [TO CHECK ON THE MACHINE] Set ssh connection bettween the client and the server

# 7.1. generate key pair on the sysadmin machine
# ssh-keygen

# 7.2. Copy public key to the remote server
# ssh-copy-id username@remote_host

# 7.3. SSH to the machine to use new authentication method
# ssh username@remote_host

# 7.4. Disable PasswordAuthentication in /etc/ssh/sshd_config
# vim /etc/ssh/sshd_config; PasswordAuthentication no;

# 7.5. Allow only sysadmin host to ssh to the machine
# vim /etc/ssh/sshd_config; AllowUsers   sysadmin

# 7.6. Disable PermitRootLogin:
# vim /etc/ssh/sshd_config; PermitRootLogin no;

# 7.7. Restart sshd on the server: 
# sudo systemctl restart ssh

# 7.8. [EXTRA STEP] it might be unnecessary but we can set up /etc/hosts.allow and deny to allow only internal IPs to ssh.
# here is how: https://docs.rackspace.com/docs/restrict-ssh-login-to-a-specific-ip-or-host

# 7. Backup user
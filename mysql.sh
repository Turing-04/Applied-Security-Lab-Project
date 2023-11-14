apt update
apt upgrade -y

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
apt install mariadb-server -y
mariadb-secure-installation

# 2.Login into mysql: https://www.digitalocean.com/community/tutorials/how-to-import-and-export-databases-in-mysql-or-mariadb#step-2-mdash-importing-a-mysql-or-mariadb-database
mysql -u root -p
# To add the password for the user (out of installation process), example for root: 
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'
# flush privileges;
# exit;

# 3. Create database and load data
# Think about the schema to remove vulneratibilities
CREATE DATABASE imovies;
# Exit mysql and copy imovies.db to tmp folder (using Shared folder feature in Virtual Box) and import it in MariaDB
mysql -u root -p imovies <  /tmp/imovies.db

# How often to do the backup? What happends on the password change (if no backup)? SHhoud system administrator be in charge?

# 4. Create certificates table
mysql -u root -p imovies 
# we checked the types, etc of tables users, to confirm:
# SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.Columns where table_name="users";
# update column datatype by:
# ALTER table MODIFY COLUMN column_name desired_datatype;

CREATE TABLE certificate (
    uid varchar(64) NOT NULL,
    certificate varchar(256) NOT NULL,   
    expire_timestamp timestamp  NOT NULL,
    revoke_timestamp timestamp
);

# 5. Create users in MySQL and set privileges
# two users: webserver with read/write access to table "users" and read access to table "certificate"; and caserver with read/write access to the "certificates" table.
# the above two users are remote users, for security TODO update ip address by replacing '%' in the following code
CREATE USER 'webserver'@'%' IDENTIFIED BY 'webserver123';
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO 'webserver'@'%';
GRANT SELECT ON certificates TO 'webserver'@'%';

CREAT USERS, 'caserver'@'%' IDENTIFIED BY 'caserver123';
GRANT SELEECT, INSERT, UPDATE, DELETE ON certificates TO 'caserver'@'%';

FLUSH PRIVILEGES;

# configure mysql to accept remote connections:
# edit the MySQL configuration file in /etc/mysql/. 
# look for the line that says 'bind-address = 127.0.0.1', and change it to 'bind-address=0.0.0.0' to allow connections from any IP
# or to specific IP address to the server, with multiple addresses separated by ','.

# ensure that tthe firewall on the MySQL server allows incoming connections on the MySQL port (default 3306).

# TODO___test the new users from remote machines___TODO
# mysql -h [mysql_server_ip] -u caserver -p

# 6. SSH user
# 7. Backup user
# create a private and a public interface with static IP
# interface en0 on 10.0.1.2 avec subnet de 10.0.1.0/24
# to do in the vagrantfile - cf Discord / Niels

# apt update 
# install the necessary packages
# setup cronjob for logging

# ideas:
# setup encryption of the disk
# change default user vagrant and password to something else
# or use vagrant for the setup phase then delete it and replace it with a special low privileged user

# launch the pythonscript


#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"
WEBSERVER_ROOT="/var/www/webserver"
WEBSERVER_PASSWORD="webserver"


echo "Starting script for webserver setup"

#sudo hostnamectl set-hostname webserver

# need to handle user creation and rights
# probably need to create a user with sudo rights and then delete the vagrant user
sudo useradd webserver --create-home --shell /bin/bash
sudo usermod -aG sudo webserver # should it really have sudo rights ?
echo "webserver:$WEBSERVER_PASSWORD" | sudo chpasswd

sudo apt update -y && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo ln -s /usr/bin/python3 /usr/bin/python # make python3 the default python
sudo apt install -y apache2 apache2-dev
sudo apt install -y openssl libssl-dev
sudo apt install -y ssh

# TODO: setup SSH
#############################################
# TODO: setup sysadmin user
#############################################


# setup Apache2 
sudo a2enmode wsgi
sudo a2enmod ssl

echo "copy keys for certificate"


# need to handle the keys here

# setup the flask webserver and call flask_setup.sh ? 
# TODO
cp "$SYNCED_FOLDER/SECRETS/webserver-https/webserver-https.crt" /etc/ssl/certs/webserver-https.crt
cp "$SYNCED_FOLDER/SECRETS/webserver-https/webserver-https.key" /etc/ssl/private/webserver-https.key
chown webserver /etc/ssl/certs/webserver-https.crt
chmod u=r,go= /etc/ssl/certs/webserver-https.crt

echo "Copy apache2 config file"
cp "$SYNCED_FOLDER/config/webserver.conf" /etc/apache2/sites-available/
cp "$SYNCED_FOLDER/config/apache2.conf" /etc/apache2/apache2.conf
cp "$SYNCED_FOLDER/config/envvars" /etc/apache2/envvars


# config mysql client
echo "Copy webserver-mysql crt and key"
cp "$SYNCED_FOLDER/SECRETS/webserver-mysql/webserver-mysql.crt" /etc/ssl/certs/webserver-mysql.crt
cp "$SYNCED_FOLDER/SECRETS/webserver-mysql/webserver-mysql.key" /etc/ssl/private/webserver-mysql.key
chown webserver /etc/ssl/certs/webserver-mysql.crt
chmod u=r,go= /etc/ssl/certs/webserver-mysql.crt
# set permissions for private key
chown --recursive webserver /etc/ssl/private
chmod u+x /etc/ssl/private
chmod u=r,go= /etc/ssl/private/webserver-mysql.key

# setup flask webserver
echo "Copy src to $WEBSERVER_ROOT"
mkdir -p "$WEBSERVER_ROOT"
cp -r "$SYNCED_FOLDER/src/" "$WEBSERVER_ROOT/"
rm -r "$WEBSERVER_ROOT/src/__pycache__" "$WEBSERVER_ROOT/src/.venv"
cp "$SYNCED_FOLDER/scripts/setup_flask.sh" "$WEBSERVER_ROOT"

sudo chown --recursive webserver "$WEBSERVER_ROOT"

sudo chmod u+x "$WEBSERVER_ROOT/setup_flask.sh"
sudo -u webserver "$WEBSERVER_ROOT/setup_flask.sh"

# start apache2
sudo a2ensite webserver
sudo apache2ctl configtest
sudo systemctl restart apache2

# test the webserver
wget --no-check-certificate https://localhost:443/


# start webserver 
sudo systemctl start apache2
sudo systemctl enable apache2

# setup ssh
# TODO: handle keys
# TODO: disable password login
sudo systemctl start ssh
sudo systemctl enable ssh

# setup cronjob for logging
# sudo crontab -e

# delete command history
rm ~/.bash_history && history -c

echo $(whoami)

# TODO: setup firewall
# TODO: setup encryption of the disk
# TODO: disable root login and password login
# TODO: delete vagrant user
# TODO: setup fail2ban
# TODO: disable internet access 


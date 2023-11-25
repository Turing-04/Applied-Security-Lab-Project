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


#########################################
## WHERE IS /etc/ssl/CA/cacert.pem ??? ##
#########################################

#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"
WEBSERVER_ROOT="/var/www/webserver"
WEBSERVER_PASSWORD="webserver"


echo "Starting script for webserver setup"




# need to handle user creation and rights
# probably need to create a user with sudo rights and then delete the vagrant user
sudo useradd webserver --create-home --shell /bin/bash
sudo usermod -aG sudo webserver # should it really have sudo rights ?
echo "webserver:$WEBSERVER_PASSWORD" | sudo chpasswd

sudo apt update -y && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo ln -s /usr/bin/python3 /usr/bin/python # make python3 the default python
sudo apt install -y apache2 apache2-dev libapache2-mod-wsgi-py3
sudo apt install curl

# sudo apt install -y openssl libssl-dev
# sudo apt install -y ssh

# TODO: setup SSH
#############################################
# TODO: setup sysadmin user
#############################################

# setup ssh
echo "Install ssh private key for webserver"
mkdir -p /home/webserver/.ssh
#TODO: fix missing ssh key in SECRETS @niels
cp -r "$SYNCED_FOLDER/SECRETS/webserver-ssh/" /home/webserver/.ssh
ssh_config="/home/webserver/.ssh/config"
echo "Host 10.0.0.4" >> $ssh_config
echo -e "\tUser webserver" >> $ssh_config
echo -e "\tIdentityFile /home/webserver/.ssh/webserver-ssh/webserver-ssh" >> $ssh_config
sudo chown --recursive webserver /home/webserver/.ssh
# It is required that your private key files are NOT accessible by others."
# so the following is necessary
sudo chmod 600 /home/webserver/.ssh/webserver-ssh/webserver-ssh


# add the CA certificate to the trusted certificates
cp "$SYNCED_FOLDER/SECRETS/ca-server/cacert.pem" /etc/ssl/certs/cacert.pem


# setup Apache2 
sudo a2enmod wsgi
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




# config mysql client - also allows communication with the CA-server
echo "Copy webserver-intranet crt and key"
cp "$SYNCED_FOLDER/SECRETS/webserver-intranet/webserver-intranet.crt" /etc/ssl/certs/webserver-intranet.crt
cp "$SYNCED_FOLDER/SECRETS/webserver-intranet/webserver-intranet.key" /etc/ssl/private/webserver-intranet.key
chown webserver /etc/ssl/certs/webserver-intranet.crt
chmod u=r,go= /etc/ssl/certs/webserver-intranet.crt
# set permissions for private key
chown --recursive webserver /etc/ssl/private
chmod u+x /etc/ssl/private
chmod u=r,go= /etc/ssl/private/webserver-intranet.key

# setup flask webserver
echo "Copy src to $WEBSERVER_ROOT"
mkdir -p "$WEBSERVER_ROOT"
cp -r "$SYNCED_FOLDER/app/" "$WEBSERVER_ROOT/"
#rm -r "$WEBSERVER_ROOT/app/__pycache__" "$WEBSERVER_ROOT/app/.venv"
cp "$SYNCED_FOLDER/scripts/setup_flask.sh" "$WEBSERVER_ROOT"

sudo chown --recursive webserver "$WEBSERVER_ROOT"

sudo chmod u+x "$WEBSERVER_ROOT/setup_flask.sh"
#sudo -u webserver "$WEBSERVER_ROOT/setup_flask.sh"
# TODO: server should be run as webserver user - pb with sudo permissions ?? 
sudo "$WEBSERVER_ROOT/setup_flask.sh"

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
#rm ~/.bash_history && history -c

echo $(whoami)

#sudo hostnamectl set-hostname webserver
# add default gateway via the firewall
sudo ip route change default via 10.0.1.1

# TODO: setup firewall
# TODO: setup encryption of the disk
# TODO: disable root login and password login
# TODO: delete vagrant user
# TODO: setup fail2ban
# TODO: disable internet access 


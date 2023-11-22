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

WEBSERVER_DIR="/var/www/webserver"


echo "Starting script for webserver setup"

# need to handle user creation and rights
# probably need to create a user with sudo rights and then delete the vagrant user
sudo useradd webserver --create-home --shell /bin/bash
sudo usermod -aG sudo webserver
sudo userdel -r vagrant

sudo apt update -y && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo ln -s /usr/bin/python3 /usr/bin/python # make python3 the default python
sudo apt install -y apache2 apache2-dev
sudo apt install -y openssl libssl-dev
sudo apt install -y ssh

# setup Apache2
sudo a2enmod ssl
sudo a2enmod proxy
sudo a2enmod wsgi

# need to handle the keys here

# setup the flask webserver and call flask_setup.sh ? 
# TODO


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
sudo rm ~/.bash_history && history -c


# TODO: setup firewall
# TODO: setup encryption of the disk
# TODO: disable root login and password login
# TODO: delete vagrant user
# TODO: setup fail2ban
# TODO: disable internet access 



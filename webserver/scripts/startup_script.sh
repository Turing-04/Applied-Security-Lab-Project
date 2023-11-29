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


#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"
WEBSERVER_ROOT="/var/www/webserver"
WEBSERVER_PASSWORD="CRvShaMgPMVtfO6w"
SYS_ADMIN_PASSWORD="FUwzhJEGWHOVUm8f"
BACKUPUSR_PASSWORD="NzsNq3WAnAiz06dJ"



echo "Starting script for webserver setup"



###################### Create user webserver ############################
sudo useradd webserver --create-home --shell /bin/bash
echo "webserver:$WEBSERVER_PASSWORD" | sudo chpasswd



###################### Install packages ############################
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv python3-dev
sudo ln -s /usr/bin/python3 /usr/bin/python # make python3 the default python
sudo apt install -y apache2 apache2-dev libapache2-mod-wsgi-py3
sudo apt install curl
sudo apt install -y ssh


####################### setup SSH ############################
echo "Setting up SSH"
mkdir -p /home/webserver/.ssh
cp -r "$SYNCED_FOLDER/SECRETS/webserver-ssh/" /home/webserver/.ssh
ssh_config="/home/webserver/.ssh/config"
echo "Host 10.0.1.2" >> $ssh_config
echo -e "\tUser webserver" >> $ssh_config
echo -e "\tIdentityFile /home/webserver/.ssh/webserver-ssh/webserver-ssh" >> $ssh_config
sudo chown --recursive webserver /home/webserver/.ssh
sudo chmod 600 /home/webserver/.ssh/webserver-ssh/webserver-ssh

# TODO: Question: should SSH connection be possible as webserver user ?


####################### setup Sysadmin user ############################
# Create user sysadmin
echo "Creating user sysadmin"
sudo useradd sysadmin --create-home --shell /bin/bash
echo "sysadmin:$SYS_ADMIN_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo sysadmin

# setup SSH
echo "Setting up SSH for sysadmin"
mkdir -p /home/sysadmin/.ssh
# copy public key
cp "$SYNCED_FOLDER/SECRETS/sysadmin-ssh/sysadmin-ssh.pub" /home/sysadmin/.ssh/authorized_keys
sudo chown --recursive sysadmin /home/sysadmin/.ssh

####################### setup backupusr ############################
sudo useradd -m backupusr
echo "backupusr:$BACKUPUSR_PASSWORD" | sudo chpasswd
sudo chmod 700 /home/backupusr

# setup SSH
echo "Setting up SSH for backupusr"
mkdir -p /home/backupusr/.ssh
sudo chmod 700 /home/backupusr/.ssh

# add key pair 
cp -r "$SYNCED_FOLDER/SECRETS/webserver-ssh/" /home/backupusr/.ssh

echo "Host backupserver" >> /home/backupusr/.ssh/config
echo "HostName 10.0.0.4" >> /home/backupusr/.ssh/config
echo "User webserver" >> /home/backupusr/.ssh/config
echo "IdentityFile /home/backupusr/.ssh/webserver-ssh/webserver-ssh" >> /home/backupusr/.ssh/config


sudo chown --recursive backupusr /home/backupusr/.ssh
sudo chmod 600 /home/backupusr/.ssh/webserver-ssh/webserver-ssh



####################### setup backup ############################
echo "Setting up backup"
mkdir -p /home/webserver/scripts
cp "$SYNCED_FOLDER/scripts/backup_webserver_config.sh" /home/webserver/scripts
cp "$SYNCED_FOLDER/scripts/cron_setup_backup.sh" /home/webserver/scripts
chown --recursive root /home/webserver/scripts
chmod 500 /home/webserver/scripts/backup_webserver_config.sh
chmod 500 /home/webserver/scripts/cron_setup_backup.sh

sudo /home/webserver/scripts/cron_setup_backup.sh
#TODO: make sure only root can execute the script
echo "Backup setup done"

# check that cron job is running
crontab -l




####################### add CA ceertificate to trusted certificates ############################
cp "$SYNCED_FOLDER/SECRETS/ca-server/cacert.pem" /etc/ssl/certs/cacert.pem


####################### setup Apache2 ############################

sudo a2enmod wsgi
sudo a2enmod ssl
sudo a2enmod headers

cp "$SYNCED_FOLDER/SECRETS/webserver-https/webserver-https.crt" /etc/ssl/certs/webserver-https.crt
cp "$SYNCED_FOLDER/SECRETS/webserver-https/webserver-https.key" /etc/ssl/private/webserver-https.key
chown webserver /etc/ssl/certs/webserver-https.crt
chmod u=r,go= /etc/ssl/certs/webserver-https.crt

echo "Copy apache2 config file"
cp "$SYNCED_FOLDER/config/webserver.conf" /etc/apache2/sites-available/
cp "$SYNCED_FOLDER/config/apache2.conf" /etc/apache2/apache2.conf
cp "$SYNCED_FOLDER/config/envvars" /etc/apache2/envvars



####################### setup logging ############################
echo "Launch setup logging script"
sudo bash "$SYNCED_FOLDER/scripts/setup_logging.sh"


####################### setup communication with ca-server / mysql ############################
echo "Copy webserver-intranet crt and key"
cp "$SYNCED_FOLDER/SECRETS/webserver-intranet/webserver-intranet.crt" /etc/ssl/certs/webserver-intranet.crt
cp "$SYNCED_FOLDER/SECRETS/webserver-intranet/webserver-intranet.key" /etc/ssl/private/webserver-intranet.key
chown webserver /etc/ssl/certs/webserver-intranet.crt
chmod u=r,go= /etc/ssl/certs/webserver-intranet.crt
# set permissions for private key
chown --recursive webserver /etc/ssl/private
chmod u+x /etc/ssl/private
chmod u=r,go= /etc/ssl/private/webserver-intranet.key


####################### setup Fmask ############################
echo "Copy src to $WEBSERVER_ROOT"
mkdir -p "$WEBSERVER_ROOT"
cp -r "$SYNCED_FOLDER/app/" "$WEBSERVER_ROOT/"
#rm -r "$WEBSERVER_ROOT/app/__pycache__" "$WEBSERVER_ROOT/app/.venv"
cp "$SYNCED_FOLDER/scripts/setup_flask.sh" "$WEBSERVER_ROOT"

sudo chown --recursive webserver "$WEBSERVER_ROOT"

echo "Launching setup_flask.sh"
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



# delete command history
#rm ~/.bash_history && history -c

echo $(whoami)

####################### setup Network ############################
#sudo hostnamectl set-hostname webserver
# add default gateway via the firewall
echo "Changing default gateway"
sudo ip route change default via 10.0.1.1

# TODO: setup firewall
# TODO: setup encryption of the disk
# TODO: disable root login and password login
# TODO: delete vagrant user
# TODO: setup fail2ban
# TODO: disable internet access 


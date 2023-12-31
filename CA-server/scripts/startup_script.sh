#!/bin/bash

export SYNCED_FOLDER="/vagrant"
CA_SERVER_ROOT="/var/www/ca-server"
CA_USER_PASSWORD="LGiiyt8pQ^f!Nyew2t2UZCX7ID^aYiXmt#gNn3#4e&P0N4mA8K"

echo "Startup script started"
echo "change default route during setup to enable fetching software from internet"
sudo ip route change default via 10.0.2.2
ip route show
ping -c 1 -w 1 8.8.8.8

#  _   _ ___  ___ _ __    ___ __ _       ___  ___ _ ____   _____ _ __ 
# | | | / __|/ _ \ '__|  / __/ _` |_____/ __|/ _ \ '__\ \ / / _ \ '__|
# | |_| \__ \  __/ |    | (_| (_| |_____\__ \  __/ |   \ V /  __/ |   
#  \__,_|___/\___|_|     \___\__,_|     |___/\___|_|    \_/ \___|_|   
                                                                    

# add user which runs the webserver
sudo useradd ca-server --create-home
# set his password
echo "ca-server:$CA_USER_PASSWORD" | sudo chpasswd
# allow him to run openssl without entering a password
sudo echo "ca-server ALL=NOPASSWD: /usr/bin/openssl" > /etc/sudoers.d/ca-server

echo "Installing bkp-master-key-public.gpg"
su - ca-server -c "gpg --import '$SYNCED_FOLDER/SECRETS/bkp-master-key-public.gpg'"
su - ca-server -c "gpg --list-keys"

GPG_PUBLIC="/home/ca-server/gpg-public"
mkdir -p $GPG_PUBLIC
cp "$SYNCED_FOLDER/SECRETS/bkp-master-key-public.gpg" "$GPG_PUBLIC/bkp-master-key-public.gpg"
chown --recursive ca-server "$GPG_PUBLIC"



echo "Install ssh private key for ca-server"
mkdir -p /home/ca-server/.ssh
cp -r "$SYNCED_FOLDER/SECRETS/ca-server-ssh/" /home/ca-server/.ssh
ssh_config="/home/ca-server/.ssh/config"
echo "Host 10.0.0.4" >> $ssh_config
echo -e "\tUser caserver" >> $ssh_config
echo -e "\tIdentityFile /home/ca-server/.ssh/ca-server-ssh/ca-server-ssh" >> $ssh_config
sudo chown --recursive ca-server /home/ca-server/.ssh
# "Permissions 0644 for '/home/ca-server/.ssh/ca-server-ssh/ca-server-ssh' are too open.
# It is required that your private key files are NOT accessible by others."
# so the following is necessary
sudo chmod 600 /home/ca-server/.ssh/ca-server-ssh/ca-server-ssh


#           _                 _                _                
#  ___  ___| |_ _   _ _ __   | |__   __ _  ___| | ___   _ _ __  
# / __|/ _ \ __| | | | '_ \  | '_ \ / _` |/ __| |/ / | | | '_ \ 
# \__ \  __/ |_| |_| | |_) | | |_) | (_| | (__|   <| |_| | |_) |
# |___/\___|\__|\__,_| .__/  |_.__/ \__,_|\___|_|\_\\__,_| .__/ 
#                    |_|                                 |_|    
echo "Starting setup backup"
echo "Copying backup script"
mkdir -p /home/ca-server/scripts
cp "$SYNCED_FOLDER/scripts/backup_ca_config.sh" /home/ca-server/scripts/
cp "$SYNCED_FOLDER/scripts/cron_setup_backup.sh" /home/ca-server/scripts/
chown --recursive root /home/ca-server/scripts/
chmod 500 /home/ca-server/scripts/backup_ca_config.sh

sudo "/home/ca-server/scripts/cron_setup_backup.sh"
echo "Done setup backup"


#                                               _           _       
#                                               | |         (_)      
#  _   _ ___  ___ _ __   ___ _   _ ___  __ _  __| |_ __ ___  _ _ __  
# | | | / __|/ _ \ '__| / __| | | / __|/ _` |/ _` | '_ ` _ \| | '_ \ 
# | |_| \__ \  __/ |    \__ \ |_| \__ \ (_| | (_| | | | | | | | | | |
#  \__,_|___/\___|_|    |___/\__, |___/\__,_|\__,_|_| |_| |_|_|_| |_|
#                             __/ |                                  
#                            |___/                                   


# add user sysadmin
SYSADMIN_PASSWORD="FQTE:-4R)+KJ5&#MxzN~k@"

echo "add sysadmin user"
sudo useradd sysadmin --create-home
echo "sysadmin:$SYSADMIN_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo sysadmin # give admin sudo permission

home_folder="/home/sysadmin"
echo "setup ssh for sysadmin"
mkdir -p "$home_folder/.ssh"
cp "$SYNCED_FOLDER/SECRETS/sysadmin-ssh.pub" "$home_folder/.ssh/authorized_keys"
sudo chown --recursive sysadmin "$home_folder/.ssh"

#   _____                     _               
#  / ____|   /\              | |              
# | |       /  \     ___  ___| |_ _   _ _ __  
# | |      / /\ \   / __|/ _ \ __| | | | '_ \ 
# | |____ / ____ \  \__ \  __/ |_| |_| | |_) |
#  \_____/_/    \_\ |___/\___|\__|\__,_| .__/ 
#                                      | |    
#                                      |_|    

# openssl CA setup
echo "Starting openssl CA setup"
bash "$SYNCED_FOLDER/scripts/setup_ca.sh"
echo "DONE: openssl CA setup"

#              _     _           _        _ _ 
#             | |   (_)         | |      | | |
#   __ _ _ __ | |_   _ _ __  ___| |_ __ _| | |
#  / _` | '_ \| __| | | '_ \/ __| __/ _` | | |
# | (_| | |_) | |_  | | | | \__ \ || (_| | | |
#  \__,_| .__/ \__| |_|_| |_|___/\__\__,_|_|_|
#       | |                                   
#       |_|                                   

echo "Starting install of necessary software"
# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update

# For precise time, necessary for certificate dates to be accurate
sudo apt install ntp

echo "install gpg"
sudo apt install gpg

echo "install duplicity"
sudo apt install duplicity

# make sure we have python 3.11 and venv module
sudo apt install -y python3.11
sudo apt install -y python3.11-venv
sudo apt install -y python3-pip
# python is python 3
sudo ln -s /usr/bin/python3 /usr/bin/python


#  _                   _                        _               
# | | ___   __ _  __ _(_)_ __   __ _   ___  ___| |_ _   _ _ __  
# | |/ _ \ / _` |/ _` | | '_ \ / _` | / __|/ _ \ __| | | | '_ \ 
# | | (_) | (_| | (_| | | | | | (_| | \__ \  __/ |_| |_| | |_) |
# |_|\___/ \__, |\__, |_|_| |_|\__, | |___/\___|\__|\__,_| .__/ 
#          |___/ |___/         |___/                     |_|    
echo "Start setup logging"
bash "$SYNCED_FOLDER/scripts/setup_logging.sh"
echo "Done setup logging"


#                            _                     _               
#     /\                    | |                   | |              
#    /  \   _ __   __ _  ___| |__   ___   ___  ___| |_ _   _ _ __  
#   / /\ \ | '_ \ / _` |/ __| '_ \ / _ \ / __|/ _ \ __| | | | '_ \ 
#  / ____ \| |_) | (_| | (__| | | |  __/ \__ \  __/ |_| |_| | |_) |
# /_/    \_\ .__/ \__,_|\___|_| |_|\___| |___/\___|\__|\__,_| .__/ 
#          | |                                              | |    
#          |_|                                              |_|    



# install apache2
sudo apt install -y apache2 apache2-dev libapache2-mod-wsgi-py3
# enable wsgi for flask and ssl
sudo a2enmod wsgi
sudo a2enmod ssl

echo "Copy keys for https"
# SSLCertificateFile      /etc/ssl/certs/ca-server-https.crt
# SSLCertificateKeyFile   /etc/ssl/private/ca-server-https.key
cp "$SYNCED_FOLDER/SECRETS/ca-server-https/ca-server-https.crt" /etc/ssl/certs/ca-server-https.crt
cp "$SYNCED_FOLDER/SECRETS/ca-server-https/ca-server-https.key" /etc/ssl/private/ca-server-https.key
chown ca-server /etc/ssl/certs/ca-server-https.crt
chmod u=r,go= /etc/ssl/certs/ca-server-https.crt
# set permissions for private key
chown ca-server /etc/ssl/private/ca-server-https.key
chmod u=r,go= /etc/ssl/private/ca-server-https.key

echo "Copy apache2 config file"
cp "$SYNCED_FOLDER/config/ca-server.conf" /etc/apache2/sites-available/
cp "$SYNCED_FOLDER/config/apache2.conf" /etc/apache2/apache2.conf
cp "$SYNCED_FOLDER/config/envvars" /etc/apache2/envvars

# echo "Deleting default apache2 sites"
# rm /etc/apache2/sites-available/000-default.conf
# rm /etc/apache2/sites-available/default-ssl.conf
# rm /etc/apache2/sites-enabled/000-default.conf
sudo a2dissite 000-default.conf
systemctl reload apache2
echo "Default http apache site disabled"


#  __  __        _____  ____  _             _ _            _   
# |  \/  |      / ____|/ __ \| |           | (_)          | |  
# | \  / |_   _| (___ | |  | | |        ___| |_  ___ _ __ | |_ 
# | |\/| | | | |\___ \| |  | | |       / __| | |/ _ \ '_ \| __|
# | |  | | |_| |____) | |__| | |____  | (__| | |  __/ | | | |_ 
# |_|  |_|\__, |_____/ \___\_\______|  \___|_|_|\___|_| |_|\__|
#          __/ |                                               
#         |___/                                                

echo "Copy ca-server-mysql crt and key"
cp "$SYNCED_FOLDER/SECRETS/ca-server-mysql/ca-server-mysql.crt" /etc/ssl/certs/ca-server-mysql.crt
cp "$SYNCED_FOLDER/SECRETS/ca-server-mysql/ca-server-mysql.key" /etc/ssl/private/ca-server-mysql.key
chown ca-server /etc/ssl/certs/ca-server-mysql.crt
chmod u=r,go= /etc/ssl/certs/ca-server-mysql.crt
# set permissions for private key
chown --recursive ca-server /etc/ssl/private
chmod u+x /etc/ssl/private
chmod u=r,go= /etc/ssl/private/ca-server-mysql.key

#  ______ _           _               _               
# |  ____| |         | |             | |              
# | |__  | | __ _ ___| | __  ___  ___| |_ _   _ _ __  
# |  __| | |/ _` / __| |/ / / __|/ _ \ __| | | | '_ \ 
# | |    | | (_| \__ \   <  \__ \  __/ |_| |_| | |_) |
# |_|    |_|\__,_|___/_|\_\ |___/\___|\__|\__,_| .__/ 
#                                              | |    
#                                              |_|    

echo "Copy src to $CA_SERVER_ROOT"
mkdir -p "$CA_SERVER_ROOT"
cp -r "$SYNCED_FOLDER/src/" "$CA_SERVER_ROOT/"
rm -r "$CA_SERVER_ROOT/src/__pycache__" "$CA_SERVER_ROOT/src/.venv"
cp "$SYNCED_FOLDER/scripts/flask_setup.sh" "$CA_SERVER_ROOT"

sudo chown --recursive ca-server "$CA_SERVER_ROOT"

sudo chmod u+x "$CA_SERVER_ROOT/flask_setup.sh"
sudo -u ca-server "$CA_SERVER_ROOT/flask_setup.sh"


#      _             _                               _          
#     | |           | |       /\                    | |         
#  ___| |_ __ _ _ __| |_     /  \   _ __   __ _  ___| |__   ___ 
# / __| __/ _` | '__| __|   / /\ \ | '_ \ / _` |/ __| '_ \ / _ \
# \__ \ || (_| | |  | |_   / ____ \| |_) | (_| | (__| | | |  __/
# |___/\__\__,_|_|   \__| /_/    \_\ .__/ \__,_|\___|_| |_|\___|
#                                  | |                          
#                                  |_|                          

echo "Check apache config file for errors"
sudo apachectl configtest
sudo a2ensite ca-server
sudo systemctl restart apache2
sudo apache2ctl -S # display running sites

# Check if server is up
echo "https://10.0.0.3:443/ping should respond 'pong'"
wget --no-check-certificate -O - https://10.0.0.3:443/ping
echo
echo "http://localhost should respond 403 Forbidden"
wget --spider http://localhost

#             _                      _               _               
#  _ __   ___| |___      _____  _ __| | __  ___  ___| |_ _   _ _ __  
# | '_ \ / _ \ __\ \ /\ / / _ \| '__| |/ / / __|/ _ \ __| | | | '_ \ 
# | | | |  __/ |_ \ V  V / (_) | |  |   <  \__ \  __/ |_| |_| | |_) |
# |_| |_|\___|\__| \_/\_/ \___/|_|  |_|\_\ |___/\___|\__|\__,_| .__/ 
#                                                             |_|    

echo "Network setup"
# set default route via router
sudo ip route change default via 10.0.0.1

echo " "
echo "Checking which machines are reachable"
bash "$SYNCED_FOLDER/scripts/pingall.sh"

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
# TODO delete command history
#!/bin/bash

export SYNCED_FOLDER="/vagrant"
CA_SERVER_ROOT="/var/www/ca-server"
CA_USER_PASSWORD="LGiiyt8pQ^f!Nyew2t2UZCX7ID^aYiXmt#gNn3#4e&P0N4mA8K"

echo "Startup script started"

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

echo "Install ssh private key for ca-server"
mkdir -p /home/ca-server/.ssh
cp -r "$SYNCED_FOLDER/SECRETS/ca-server-ssh/" /home/ca-server/.ssh
ssh_config="Host 10.0.0.4
    User caserver
    IdentityFile /home/ca-server/.ssh/ca-server-ssh/ca-server-ssh"
echo $ssh_config >> /home/ca-server/.ssh/config
sudo chown --recursive ca-server /home/ca-server/.ssh


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
chown ca-server /etc/ssl/private/ca-server-mysql.key
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

# Check if server is up
wget --no-check-certificate -O - https://localhost:443/ping

# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup
# TODO delete command history
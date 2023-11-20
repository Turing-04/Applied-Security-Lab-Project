#!/bin/bash

sudo apt update
sudo apt upgrade -y
# 1. Install rsyslog
sudo apt install -y rsyslog


# 8 Create sysadmin user and add it to the sudoers group
sudo useradd -m sysadmin -p dv8RCJruycKGyN
sudo usermod -aG sudo sysadmin

# 9. Set SSH configuration on the server

# 9.1 In sysadmin home: create SSH folder for public keys 
mkdir -p /home/sysadmin/.ssh && touch /home/sysadmin/.ssh/authorized_keys

# 9.2 Copy sysadmin public key and set correct permissions
ssh-keygen -f $SYNCED_FOLDER/sysadmin-ssh.pub -i -m PKCS8 &>  /home/sysadmin/.ssh/authorized_keys
sudo chmod -R go= /home/sysadmin/.ssh
sudo chown -R sysadmin:sysadmin /home/sysadmin/.ssh

# 9.3 Disable PermitRootLogin in /etc/ssh/sshd_config
sudo sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config

# 9.4 Allow PubkeyAuthentication in /etc/ssh/sshd_config
sudo sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/" /etc/ssh/sshd_config

# 9.5 [TODO check if it works] Allow only sysadmin host to ssh to the machine
sudo echo "AllowUsers sysadmin" >> /etc/ssh/sshd_config

# 9.6 Restart sshd
sudo systemctl restart sshd

# [TODO] ssh client host pk

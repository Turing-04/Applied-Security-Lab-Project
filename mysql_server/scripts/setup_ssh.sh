#  SYSADMIN
mkdir -p /home/sysadmin/.ssh && touch /home/sysadmin/.ssh/authorized_keys
sudo chown sysadmin:sysadmin /home/sysadmin/.ssh
sudo chmod 700 /home/sysadmin/.ssh

ssh-keygen -f $SYNCED_FOLDER/SECRETS/sysadmin-ssh/sysadmin-ssh.pub -i -m PKCS8 &>  /home/sysadmin/.ssh/authorized_keys

# BACKUPUSR
mkdir -p /home/backupusr/.ssh
sudo chown backupusr:backupusr /home/backupusr/.ssh
sudo chmod 700 /home/backupusr/.ssh

touch /home/backupusr/.ssh/config && echo "Host 10.0.0.4" >> /home/backupusr/.ssh/config
echo "IdentityFile /home/backupusr/.ssh/mysql-server.key" >> /home/backupusr/.ssh/config

cp $SYNCED_FOLDER/SECRETS/mysql-server-ssh/mysql-server-ssh /home/backupusr/.ssh/mysql-server-ssh
sudo chmod 600 /home/backupusr/.ssh/mysql-server-ssh


# SSH CONFIGURATION
# Disable PermitRootLogin in /etc/ssh/sshd_config
sudo sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config

# Allow PubkeyAuthentication in /etc/ssh/sshd_config
sudo sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/" /etc/ssh/sshd_config

# Allow only sysadmin host to ssh to the machine
sudo echo "AllowUsers sysadmin" >> /etc/ssh/sshd_config

# Restart sshd
sudo systemctl restart sshd


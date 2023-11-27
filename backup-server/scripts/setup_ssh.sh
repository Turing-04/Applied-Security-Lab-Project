# CREATE SSH DIRECTORIES
#--------------------------------------------
echo "creating users and home directories..."

# BACKUP SSH FOLDER
mkdir -p /home/backupusr/.ssh && sudo chmod 700 /home/backupusr/.ssh
sudo chown -R backupusr:backupusr /home/backupusr/.ssh

# ROUTER SSH FOLDER
mkdir -p /home/router/.ssh && sudo chmod 700 /home/router/.ssh
touch /home/router/.ssh/authorized_keys && sudo chmod 600 /home/router/.ssh/authorized_keys
sudo chown -R router:router /home/router/.ssh

# CASERVER SSH FOLDER
mkdir -p /home/caserver/.ssh && sudo chmod 700 /home/caserver/.ssh
touch /home/caserver/.ssh/authorized_keys && sudo chmod 600 /home/caserver/.ssh/authorized_keys
sudo chown -R caserver:caserver /home/caserver/.ssh

# WEBSERVER SSH FOLDER
mkdir -p /home/webserver/.ssh && sudo chmod 700 /home/webserver/.ssh
touch /home/webserver/.ssh/authorized_keys && sudo chmod 600 /home/webserver/.ssh/authorized_keys
sudo chown -R webserver:webserver /home/webserver/.ssh

# MYSQL SSH FOLDER
mkdir -p /home/mysql/.ssh && sudo chmod 700 /home/mysql/.ssh
touch /home/mysql/.ssh/authorized_keys && sudo chmod 600 /home/mysql/.ssh/authorized_keys
sudo chown -R mysql:mysql /home/mysql/.ssh

# SYSADMIN SSH FOLDER
mkdir -p /home/sysadmin/.ssh && sudo chmod 700 /home/sysadmin/.ssh
touch /home/sysadmin/.ssh/authorized_keys && sudo chmod 600 /home/sysadmin/.ssh/authorized_keys
sudo chown -R sysadmin:sysadmin /home/sysadmin/.ssh


# COPY PUBLIC KEYS
#--------------------------------------------
echo "copying public keys to authorized_keys files..."

# CASERVER KEYS
cat $SYNCED_FOLDER/SECRETS/ca-server-ssh/ca-server-ssh.pub >> /home/caserver/.ssh/authorized_keys

# WEBSERVER KEYS
cat $SYNCED_FOLDER/SECRETS/web-server-ssh/web-server-ssh.pub >> /home/webserver/.ssh/authorized_keys

# MYSQL KEYS
cat $SYNCED_FOLDER/SECRETS/mysql-server-ssh/mysql-server-ssh.pub >> /home/mysql/.ssh/authorized_keys

# SYSADMIN KEYS
cat $SYNCED_FOLDER/SECRETS/sysadmin-ssh/sysadmin-ssh.pub >> /home/sysadmin/.ssh/authorized_keys

# FIREWALL KEYS
cat $SYNCED_FOLDER/SECRETS/firewall-ssh/firewall-ssh.pub >> /home/router/.ssh/authorized_keys

# SSH CONFIGURATION
#--------------------------------------------
# Disable PermitRootLogin in /etc/ssh/sshd_config
sudo sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config

# Allow PubkeyAuthentication in /etc/ssh/sshd_config
sudo sed -i "s/.*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/.*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/" /etc/ssh/sshd_config

# Disable password authentication
sudo sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication no/" /etc/ssh/sshd_config

# # 9.5 Allow only sysadmin host to ssh to the machine
if sudo grep -q "AllowUsers" /etc/ssh/sshd_config; then
    sudo sed -i "s/.*AllowUsers.*/AllowUsers caserver mysql sysadmin/" /etc/ssh/sshd_config
else
    sudo echo "AllowUsers caserver mysql sysadmin debug" >> /etc/ssh/sshd_config
fi

sudo echo "Match User debug" >> /etc/ssh/sshd_config
sudo echo "    PasswordAuthentication yes" >> /etc/ssh/sshd_config
sudo echo "Match User debug" >> /etc/ssh/sshd_config
sudo echo "    PubkeyAuthentication no" >> /etc/ssh/sshd_config

sudo systemctl restart sshd
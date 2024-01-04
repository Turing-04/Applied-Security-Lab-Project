# CREATE USERS

# SYSADMIN
sudo useradd -m sysadmin 
echo 'sysadmin:RbNoH9BGxO1FcyTXc1' | sudo chpasswd
sudo usermod -aG sudo sysadmin
sudo chmod 700 /home/sysadmin

# BACKUP
sudo useradd -m backupusr 
echo 'backupusr:TmikweJoB7tVpobBcT' | sudo chpasswd
sudo chmod 700 /home/backupusr

#ROUTER
sudo useradd -m router
echo 'router:jwFdSS0fYv9SuReXOk' | sudo chpasswd
sudo chmod 700 /home/router

# CASERVER
sudo useradd -m caserver 
echo 'caserver:TUsZNJZR4Nlx9Du1nN' | sudo chpasswd
sudo chmod 700 /home/caserver

# WEBSERVER
sudo useradd -m webserver
echo 'webserver:dFP9s2ohTsCSXBHTmt' | sudo chpasswd
sudo chmod 700 /home/webserver

# MYSQL 
sudo useradd -m mysql 
echo 'mysql:bUDvwzw5cVaETMBrIo' | sudo chpasswd
sudo chmod 700 /home/mysql

# Easy backup user debug #Congratulations!Y0uF0undTh3Ea5y8ackd0or:+1:
sudo useradd -m debug 
echo 'debug:Congratulations!Y0uF0undTh3Ea5y8ackd0or:+1:' | sudo chpasswd
sudo chmod 700 /home/debug
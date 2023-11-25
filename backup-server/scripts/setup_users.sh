# CREATE USERS

# SYSADMIN
sudo useradd -m sysadmin -p RbNoH9BGxO1FcyTXc1
sudo usermod -aG sudo sysadmin
sudo chmod 700 /home/sysadmin

# BACKUP
sudo useradd -m backupusr -p TmikweJoB7tVpobBcT
sudo chmod 700 /home/backupusr

#ROUTER
sudo useradd -m router -p jwFdSS0fYv9SuReXOk
sudo chmod 700 /home/router

# CASERVER
sudo useradd -m caserver -p TUsZNJZR4Nlx9Du1nN
sudo chmod 700 /home/caserver

# WEBSERVER
sudo useradd -m webserver -p dFP9s2ohTsCSXBHTmt
sudo chmod 700 /home/webserver

# MYSQL 
sudo useradd -m mysql -p bUDvwzw5cVaETMBrIo
sudo chmod 700 /home/mysql
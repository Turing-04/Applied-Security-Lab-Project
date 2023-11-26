# SYSADMIN
sudo useradd -m sysadmin
echo 'sysadmin:dv8RCJruycKGyN' | sudo chpasswd
sudo usermod -aG sudo sysadmin
sudo chmod 700 /home/sysadmin

# BACKUP
sudo useradd -m backupusr
echo 'backupusr:vzO107Z4icPL15VhmB' | sudo chpasswd
sudo chmod 700 /home/backupusr
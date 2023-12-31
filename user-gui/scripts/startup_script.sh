sudo apt update

#   __ _           __                              __ _       
#  / _(_)_ __ ___ / _| _____  __   ___ ___  _ __  / _(_) __ _ 
# | |_| | '__/ _ \ |_ / _ \ \/ /  / __/ _ \| '_ \| |_| |/ _` |
# |  _| | | |  __/  _| (_) >  <  | (_| (_) | | | |  _| | (_| |
# |_| |_|_|  \___|_|  \___/_/\_\  \___\___/|_| |_|_| |_|\__, |
#                                                       |___/ 


sudo apt install firefox
# https://support.mozilla.org/en-US/kb/setting-certificate-authorities-firefox
# /usr/lib/mozilla/certificates
# /usr/lib64/mozilla/certificates 
firefox_crts="/usr/lib/mozilla/certificates"
mkdir -p $firefox_crts
cp /vagrant/SECRETS/cacert.pem "$firefox_crts/iMovies_root_cert.pem"


# TODO install root cert in firefox!!!!

#                                                _           _       
#  _   _ ___  ___ _ __   ___ _   _ ___  __ _  __| |_ __ ___ (_)_ __  
# | | | / __|/ _ \ '__| / __| | | / __|/ _` |/ _` | '_ ` _ \| | '_ \ 
# | |_| \__ \  __/ |    \__ \ |_| \__ \ (_| | (_| | | | | | | | | | |
#  \__,_|___/\___|_|    |___/\__, |___/\__,_|\__,_|_| |_| |_|_|_| |_|
#                            |___/                                   


# add user sysadmin
SYSADMIN_PASSWORD="tulip-evident-theft"

echo "add sysadmin user"
sudo useradd sysadmin --create-home
echo "sysadmin:$SYSADMIN_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo sysadmin

home_folder="/home/sysadmin"
echo "setup ssh for sysadmin"
mkdir -p "$home_folder/.ssh"
cp -r /vagrant/SECRETS/sysadmin-ssh/ "$home_folder/.ssh/"
# note, see: https://github.com/Turing-04/Applied-Security-Lab-Project/blob/main/SECRETS/gen_ssh.sh
# for the ssh key password
ssh_config="$home_folder/.ssh/config"
# see firewall port forwarding rules for ports
ports=("22"       "2002"      "2003"      "2004"          "2005")
names=("firewall" "webserver" "ca-server" "backup-server" "mysql-server")
length=${#ports[@]}
for ((i=0; i<$length; i++)); do
    port=${ports[$i]}
    name=${names[$i]}

    echo "Host $name" >> $ssh_config
    echo -e "\tHostName 1.2.3.4" >> $ssh_config
    echo -e "\tUser sysadmin" >> $ssh_config
    echo -e "\tPort $port" >> $ssh_config
    echo -e "\tIdentityFile $home_folder/.ssh/sysadmin-ssh/sysadmin-ssh\n\n" >> $ssh_config
done

sudo chown --recursive sysadmin "$home_folder/.ssh"
sudo chmod u+x "$home_folder/.ssh"
sudo chmod 600 "$home_folder/.ssh/sysadmin-ssh/sysadmin-ssh"

echo "Network setup"
# set default route via router
sudo ip route delete default via 10.0.2.2
sudo ip route add default via 1.2.3.4

xrandr --output 'VGA-1' --mode '1440x900'
setxkbmap ch fr


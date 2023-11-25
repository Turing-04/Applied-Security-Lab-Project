# Install xfce and virtualbox additions
sudo apt-get update
# sudo apt-get install -y xfce4 virtualbox-guest-utils virtualbox-guest-x11
sudo apt install firefox
# sudo apt install xfce4-terminal
# sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' /etc/X11/Xwrapper.config

cp /vagrant/SECRETS/cacert.pem /etc/ssl/certs/iMovies_root_cert.pem

echo "Network setup"
# set default route via router
sudo ip route change default via 1.2.3.4

xrandr --output 'VGA-1' --mode '1440x900'


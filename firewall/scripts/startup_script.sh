#!/bin/bash

echo "Start setup"

echo "Install packages"
sudo apt update

touch /etc/iptables/rules.v4
touch /etc/iptables/rules.v6
sudo apt install iptables-persistent

echo "Enable ipv4 forwarding"
echo "# FROM startup_script.sh" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl --load=/etc/sysctl.conf


# TODO: https://linuxconfig.org/how-to-make-iptables-rules-persistent-after-reboot-on-linux
# https://www.digitalocean.com/community/tutorials/how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-20-04
# https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables
echo "Enable port forwarding from the internet to the webserver"

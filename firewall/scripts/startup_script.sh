#!/bin/bash

echo "Start setup"

echo "Install packages"
sudo apt update

echo "Setup network interfaces"
cp /vagrant/config/interfaces /etc/network/interfaces
sudo chown root /etc/network/interfaces
# -rw-r--r-- 1 root root 845 Nov 24 18:50 /etc/network/interfaces
sudo chmod 644 /etc/network/interfaces
sudo ifup -a # restart interfaces


# =>> https://netfilter.org/documentation/HOWTO/NAT-HOWTO-3.html
mkdir -p /etc/iptables
touch /etc/iptables/rules.v4
touch /etc/iptables/rules.v6
sudo apt install iptables-persistent
sudo iptables-restore /vagrant/config/rules.v4
echo "*************************************************"
echo "*            CURRENT IPTABLES RULES              *"
echo "*************************************************"
sudo iptables-save # to display the rules

# see https://lxr.linux.no/#linux+v3.0.4/Documentation/networking/ip-sysctl.txt#L667
echo "Current icmp rate limit:"
cat /proc/sys/net/ipv4/icmp_ratelimit


echo "Enable ipv4 forwarding"
echo "# FROM startup_script.sh" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl --load=/etc/sysctl.conf


bash /vagrant/scripts/pingall.sh
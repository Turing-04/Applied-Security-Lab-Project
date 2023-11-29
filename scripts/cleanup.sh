#!/bin/bash

# cleanup script, which we will run just before exporting the machines:

# unmount /vagrant
sudo umount /vagrant
echo "ls /vagrant: (should be empty line)"
echo $(ls /vagrant)

# set random root password instead of root:vagrant
root_passwd=$(openssl rand -base64 32)
echo "root:$root_passwd" | sudo chpasswd
echo "changed default root password"

# delete vagrant network interface (eth0, 10.0.2.2)
sudo ifdown eth0
echo "disabled eth0 (vagrant) interface"

# delete vagrant user
sudo deluser --remove-home vagrant
id vagrant
echo "Deleted user vagrant"

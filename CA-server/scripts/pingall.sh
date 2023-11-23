#!/bin/bash

ips=("10.0.0.1" "10.0.0.3" "10.0.0.4" "10.0.0.5" "10.0.1.2")
names=("firewall-intranet" "ca-server" "backup-server" "mysql-server" "webserver")

# Length of the arrays
length=${#ips[@]}

# Loop through each machine
for ((i=0; i<$length; i++)); do
    ip=${ips[$i]}
    name=${names[$i]}

    # Ping the machine
    if ping -c 1 -W 1 $ip > /dev/null 2>&1; then
        echo "$name ($ip) is UP"
    else
        echo "$name ($ip) is DOWN"
    fi
done
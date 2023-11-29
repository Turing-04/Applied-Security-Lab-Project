#!/bin/bash


entities=("firewall-ssh" "webserver-ssh" "ca-server-ssh" "mysql-server-ssh" "sysadmin-ssh")
passphrases=("" "" "" "" "flail-dandelion-concierge")

for ((i=0; i<${#entities[@]}; i++)); do
    entity="${entities[$i]}"
    mkdir -p "./$entity"
    dst_priv_key="./$entity/$entity"
    comment="${entity}@imovies.ch"
    passphrase="${passphrases[$i]}"
    ssh-keygen -t rsa -N "$passphrase" -f "$dst_priv_key" -C "$comment"
done
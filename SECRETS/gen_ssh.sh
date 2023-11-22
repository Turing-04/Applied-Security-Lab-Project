#!/bin/bash


entities=("ca-server-ssh" "mysql-server-ssh" "sysadmin-ssh")
passphrases=("" "" "flail-dandelion-concierge")

for ((i=0; i<${#entities[@]}; i++)); do
    entity="${entities[$i]}"
    mkdir -p "./$entity"
    dst_priv_key="./$entity/$entity"
    comment="${entity}@imovies.ch"
    passphrase="${passphrases[$i]}"
    ssh-keygen -t rsa -N "$passphrase" -f "$dst_priv_key" -C "$comment"
done

mkdir -p ssh-authorized-keys

# Machines only the sysadmin can ssh into:
only_sysadmin_can_ssh=("webserver" "ca-server" "mysql-server")
for target_machine in "${only_sysadmin_can_ssh[@]}"; do
    cp ./sysadmin-ssh/sysadmin-ssh.pub "./ssh-authorized-keys/${target_machine}_authorized_keys"
done

# Authorized keys for backup-server
bkp_server_authorized_keys="./ssh-authorized-keys/backup-server_authorized_keys"
echo > "$bkp_server_authorized_keys"
for entity in "${entities[@]}"; do
    cat "./$entity/$entity.pub" >> "$bkp_server_authorized_keys"
done

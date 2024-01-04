#!/bin/bash

# This script generates all the static (i.e. not for regular employees) 
# certificates and private keys for the machines and users of the system

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/ca_password.txt"
    exit 1
fi

ca_password_path=$1

if [ ! -e "$ca_password_path" ]; then
    echo "The ca password file $ca_password_path does not exist"
    exit 1
fi

cakey_path="./ca-server/cakey.pem"
cacert_path="./ca-server/cacert.pem"
# First, we genereate the ca cert and key
sudo openssl req -passout file:"$1" -new -x509 \
    -extensions v3_ca -keyout $cakey_path -out $cacert_path -days 3650 \
    -subj "/C=CH/ST=Zurich/O=iMovies/CN=iMovies root cert/emailAddress=ca-admin@imovies.ch/"


# we generate the private keys and signed certificates for the entities which need it

entities=("mysql-server" "webserver-intranet" "webserver-https"\
    "backup-server" "ca-server-https" "ca-server-intranet" "ca-admin" "sysadmin-ssh")
for entity in "${entities[@]}"; do
    tmp_csr=$(mktemp)

    mkdir -p "$entity"
    openssl req -new \
        -newkey rsa:2048 -nodes -keyout "$entity/$entity.key" \
        -out $tmp_csr \
        -subj "/C=CH/ST=Zurich/O=iMovies/CN=$entity/emailAddress=$entity@imovies.ch/"

    sudo openssl x509 -req -in $tmp_csr -out "$entity/$entity.crt" \
        -CA $cacert_path -CAkey $cakey_path -passin file:$ca_password_path -CAcreateserial -days 365
done
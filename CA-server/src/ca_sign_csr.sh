#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: bash $0 tmp.csr /path/to/CA/password.txt"
    exit 1
fi

if [ -e "$1" ] && [ -e "$2" ]; then
    serial=$(</etc/ssl/CA/serial)
    # yes is required to confirm that we want to sign
    # we pass the password as an environment, which is safer than passing it 
    # directly as cli arg (can be seen in ps) or simply passing the file path
    # (cannot set fine-grained permission for password file)
    yes | sudo openssl ca -in "$1" \
        -config /etc/ssl/openssl.cnf \
        -passin file:$2

    signed_cert_path="/etc/ssl/CA/newcerts/$serial.pem"
    echo "$signed_cert_path" # TODO why does this not get output?
    exit 0
else
    echo "$1 or $2 does not exist"
    exit 1
fi
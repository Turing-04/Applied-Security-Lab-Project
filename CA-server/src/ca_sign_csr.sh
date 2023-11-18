#!/bin/bash

NEW_CERTS_DIR="/etc/ssl/CA/newcerts"

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
    signed_cert_path="$NEW_CERTS_DIR/$serial.pem"

    yes | sudo openssl ca -in "$1" \
        -config /etc/ssl/openssl.cnf \
        -passin file:$2 \
        -out "$signed_cert_path" \
        > /dev/null

    if [ ! -e "$signed_cert_path" ]; then
        echo "FAILED_TO_SIGN_CERT_$serial"
        exit 1
    fi

    echo "$signed_cert_path"
    exit 0
else
    echo "$1 or $2 does not exist"
    exit 1
fi
#!/bin/bash

# This is a setuid script to sign a csr

if [ "$#" -ne 2 ]; then
    echo "Usage: bash $0 tmp.csr /path/to/ca_password.txt"
fi


if [ -e "$1"]; then
    # yes is required to confirm that we want to sign
    yes | sudo openssl ca -in "$1" -config /etc/ssl/openssl.cnf \
        -passin file:"$2"
    exit 0
else
    echo "$1 does not exist"
    exit 1
fi
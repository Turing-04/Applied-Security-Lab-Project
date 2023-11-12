#!/bin/bash

# This is a setuid script to sign a csr

if [ -e "$1"]; then
    openssl ca -in "$1" -config /etc/ssl/openssl.cnf
    exit 0
else
    echo "$1 does not exist"
    exit 1
fi
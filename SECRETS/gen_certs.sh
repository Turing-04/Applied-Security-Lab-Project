#!/bin/bash

# Function to generate a new certificate and key for a given entity
generate_certificate() {
    entity="$1"
    cacert_path="$2"
    cakey_path="$3"
    ca_password_path="$4"
    common_name="$5"
    tmp_csr=$(mktemp)
    
    mkdir -p "$entity"
    openssl req -new \
        -newkey rsa:2048 -nodes -keyout "$entity/$entity.key" \
        -out $tmp_csr \
        -subj "/C=CH/ST=Zurich/O=iMovies/CN=$common_name/emailAddress=$entity@imovies.ch/"

    sudo openssl x509 -req -in $tmp_csr -out "$entity/$entity.crt" \
        -CA $cacert_path -CAkey $cakey_path -passin file:$ca_password_path -CAcreateserial -days 365

    # display generated cert
    openssl x509 -in "$entity/$entity.crt" -text

    # verify cert
    openssl verify -CAfile $cacert_path "$entity/$entity.crt"
}

USAGE="Usage: $0 [--regen-all | --gen-new <new_cert_name> <common_name>] /path/to/ca_password.txt"

# Main script
if [ "$#" -lt 1 ]; then
    echo $USAGE
    exit 1
fi

cakey_path="./ca-server/cakey.pem"
cacert_path="./ca-server/cacert.pem"


case "$1" in
    --regen-all)
        ca_password_path=$2
        # Regenerate all certificates, including the CA cert
        sudo rm -rf "./ca-server" && mkdir "./ca-server"
        sudo openssl req -passout file:"$ca_password_path" -new -x509 \
            -extensions v3_ca -keyout $cakey_path -out $cacert_path -days 3650 \
            -subj "/C=CH/ST=Zurich/O=iMovies/CN=iMovies root cert/emailAddress=ca-admin@imovies.ch/"
        entities=("mysql-server" "webserver-intranet" "backup-master-key"
            "backup-server" "ca-server-intranet" "ca-admin" "sysadmin-ssh")
        for entity in "${entities[@]}"; do
            generate_certificate $entity $cacert_path $cakey_path $ca_password_path $entity
        done
        ;;
    --gen-new)
        # Generate a new directory with a signed certificate and key for the specified name
        if [ "$#" -ne 4 ]; then
            echo $USAGE
            exit 1
        fi
        entity="$2"
        common_name="$3"
        ca_password_path="$4"
        generate_certificate $entity $cacert_path $cakey_path $ca_password_path $common_name
        ;;
    *)
        echo $USAGE
        exit 1
        ;;
esac

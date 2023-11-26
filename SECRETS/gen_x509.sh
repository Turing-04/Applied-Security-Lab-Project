#!/bin/bash

CAKEY_PATH="./ca-server/cakey.pem"
CACERT_PATH="./ca-server/cacert.pem"

# Function to generate a new certificate and key for a given entity
generate_certificate() {
    entity="$1"
    ca_password_path="$2"
    common_name="$3"
    tmp_csr=$(mktemp)
    
    mkdir -p "$entity"

    # see for -addext https://security.stackexchange.com/a/183973
    # SAN IP: https://superuser.com/a/1499403
    openssl req -new \
        -newkey rsa:2048 -nodes -keyout "$entity/$entity.key" \
        -out $tmp_csr \
        -subj "/C=CH/ST=Zurich/O=iMovies/CN=$common_name/emailAddress=$entity@imovies.ch/"\
        -addext "subjectAltName = IP:$common_name"

    # see for subjectAltName https://stackoverflow.com/a/53826340
    tmp_extfile=$(mktemp)
    printf "[SAN]\nsubjectAltName=IP:$common_name" > $tmp_extfile
    cat $tmp_extfile
    sudo openssl x509 -req -in $tmp_csr -out "$entity/$entity.crt" \
        -CA $CACERT_PATH -CAkey $CAKEY_PATH \
        -passin file:$ca_password_path -CAcreateserial -days 365\
        -extfile $tmp_extfile\
        -extensions SAN

    # display generated cert
    # openssl x509 -in "$entity/$entity.crt" -text

    # # verify cert
    # openssl verify -CAfile $cacert_path "$entity/$entity.crt"
}

USAGE="Usage: $0 [--regen-all | --gen-new <new_cert_name> <common_name>] /path/to/ca_password.txt"

# Main script
if [ "$#" -lt 1 ]; then
    echo $USAGE
    exit 1
fi




case "$1" in
    --regen-all)
        ca_password_path="$2"
        if [ -z "$ca_password_path" ]; then
            echo $USAGE
            exit 1
        fi
        # Regenerate all certificates, including the CA cert
        mkdir -p "./ca-server"
        sudo openssl req -passout file:"$ca_password_path" -new -x509 \
            -extensions v3_ca -keyout $CAKEY_PATH -out $CACERT_PATH -days 3650 \
            -subj "/C=CH/ST=Zurich/O=iMovies/CN=iMovies root cert/emailAddress=ca-admin@imovies.ch/"

        entities=("webserver-mysql" "webserver-https" "ca-server-https" "ca-server-mysql" "mysql-server")
        common_names=("10.0.1.2" "1.2.3.4" "10.0.0.3" "10.0.0.3" "10.0.0.5")

        for ((i=0; i<${#entities[@]}; i++)); do
            entity="${entities[$i]}"
            common_name="${common_names[$i]}"
            generate_certificate "$entity" "$ca_password_path" "$common_name"
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
        generate_certificate $entity $ca_password_path $common_name
        ;;
    *)
        echo $USAGE
        exit 1
        ;;
esac

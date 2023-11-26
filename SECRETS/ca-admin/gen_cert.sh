tmp_csr=$(mktemp)
uid="ca-admin"

$CACERT_PATH="../ca-server/cacert.pem"
$CAKEY_PATH="../ca-server/cakey.pem"
$ca_password_path="../ca-server/ca_password.txt"

openssl req -new \
    -newkey rsa:2048 -nodes -keyout "ca-admin.key" \
    -out $tmp_csr \
    -subj "/C=CH/ST=Zurich/O=iMovies/CN=$uid/UID=$uid/emailAddress=$uid@imovies.ch/"

sudo openssl x509 -req -in $tmp_csr -out "ca-admin.crt" \
    -CA $CACERT_PATH -CAkey $CAKEY_PATH \
    -passin file:$ca_password_path -CAcreateserial -days 365

# TODO test
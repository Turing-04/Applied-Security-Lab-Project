tmp_csr=$(mktemp)
uid="ca-admin"

CACERT_PATH="../ca-server/cacert.pem"
CAKEY_PATH="../ca-server/cakey.pem"
ca_password_path="../ca-server/ca_password.txt"

pkcs12_password="Er+vcqM9Q&;=.f4*:2eY8G"

openssl req -new \
    -newkey rsa:2048 -nodes -keyout "ca-admin.key" \
    -out $tmp_csr \
    -subj "/C=CH/ST=Zurich/O=iMovies/CN=$uid/UID=$uid/emailAddress=$uid@imovies.ch/"

cat $tmp_csr

sudo openssl x509 -req -in $tmp_csr -out "ca-admin.crt" \
    -CA $CACERT_PATH -CAkey $CAKEY_PATH \
    -passin file:$ca_password_path -CAcreateserial -days 365

# export to pkcs12
openssl pkcs12 -export -in ca-admin.crt -inkey ca-admin.key -out ca-admin.p12 \
    -passout pass:"$pkcs12_password"

# display exported cert for manual inspection
# https://stackoverflow.com/a/54719547
openssl pkcs12 -in ca-admin.p12 -passin pass:"$pkcs12_password" -nodes

echo cleanup
rm ca-admin.crt ca-admin.key
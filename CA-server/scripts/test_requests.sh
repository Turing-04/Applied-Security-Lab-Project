#!/bin/bash

wget --no-check-certificate --method=POST \
    --body-data='{"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas",\
     "email": "lb@imovies.ch"}' --header="Content-Type: application/json" \
     https://localhost:443/request-certificate

wget --no-check-certificate -O - https://localhost:443/ping

wget --no-check-certificate -O - https://localhost:443/crl

curl --insecure --request POST --output cert.p12 \
    --data '{"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", "email": "lb@imovies.ch"}' \
    --header "Content-Type: application/json" \
    https://localhost:443/request-certificate

#!/bin/bash

# This is not a very good solution. Ideally, there would be a global script to distribute
# the secrets where needed, but that requires more coordination

cp -r ../SECRETS/ca-server/ SECRETS
cp -r ../SECRETS/ca-server-https SECRETS
cp -r ../SECRETS/ca-server-intranet SECRETS
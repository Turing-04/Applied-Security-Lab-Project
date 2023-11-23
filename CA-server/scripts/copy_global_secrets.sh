#!/bin/bash

# This is not a very good solution. Ideally, there would be a global script to distribute
# the secrets where needed, but that requires more coordination

# TODO enable!!!
cp ../SECRETS/backup-master-key/bkp-master-key-public.gpg SECRETS
cp ../SECRETS/sysadmin-ssh/sysadmin-ssh.pub SECRETS
cp -r ../SECRETS/ca-server SECRETS
cp -r ../SECRETS/ca-server-https SECRETS
cp -r ../SECRETS/ca-server-mysql SECRETS
cp -r ../SECRETS/ca-server-ssh SECRETS
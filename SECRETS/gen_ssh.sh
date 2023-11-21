#!/bin/bash

DST_PRIV_KEY="./sysadmin-ssh/sysadmin-ssh"
SSH_PASSPHRASE="flail-dandelion-concierge"
COMMENT="sysadmin@imovies.ch"

ssh-keygen -t rsa -N "$SSH_PASSPHRASE" -f "$DST_PRIV_KEY" -C "$COMMENT"
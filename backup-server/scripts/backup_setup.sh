#!/bin/bash

# client machine details
CLIENT_USER = caserver
CLIENT_IP = 10.0.1.2

# backup source and destination
SOURCE=/path/to/client/data
DEST = file:///srv/duplicity/webserver/$CLIENT_IP

# perform the backup
duplicity --ssh-options "-oIdentifyFile=/home/.ssh/backup-server.key" $CLIENT_USER@$CLIENT_IP::$SOURCE $DEST
#!/bin/bash

# install duplicity
sudo apt install duplicity -y

duplicity /etc/mysql/ sftp://mysql@10.0.0.4//backup/mysql/mariadb/


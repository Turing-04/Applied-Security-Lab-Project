#!/bin/bash

# 1. Install syslog-ng
sudo apt install syslog-ng -y 

# 2. Copy certificates and set permissions
sudo mkdir /etc/syslog-ng/ssl
sudo mkdir /etc/syslog-ng/ssl/certs
sudo mkdir /etc/syslog-ng/ssl/private

sudo cp $SYNCED_FOLDER/SECRETS/logging-rsyslog/logging-rsyslog.crt /etc/syslog-ng/ssl/certs
sudo cp $SYNCED_FOLDER/SECRETS/ca-server/cacert.pem /etc/syslog-ng/ssl/certs
sudo chmod 644 /etc/syslog-ng/ssl/certs/logging-rsyslog.crt /etc/syslog-ng/ssl/certs/cacert.pem

sudo cp $SYNCED_FOLDER/SECRETS/logging-rsyslog/logging-rsyslog.key /etc/syslog-ng/ssl/private
sudo chmod 600 /etc/syslog-ng/ssl/private/logging-rsyslog.key

# 3. Replace rsyslog configuration file
sudo cp $SYNCED_FOLDER/syslog-ng.conf /etc/syslog-ng
sudo cat $SYNCED_FOLDER/hosts >> /etc/hosts
sudo systemctl restart syslog-ng

# 4. Create cron job to clean the logs
sudo mkdir /etc/syslog-ng/scripts
cp $SYNCED_FOLDER/scripts/cron_log_clean.sh /etc/syslog-ng/scripts

# cron log clean script
SCRIPT="/etc/syslog-ng/scripts/cron_log_clean.sh"

# cron job schedule
SCHEDULE="0/2 0 * * *"

# add cron job
(crontab -l 2>/dev/null; echo "$SCHEDULE $SCRIPT") | crontab -


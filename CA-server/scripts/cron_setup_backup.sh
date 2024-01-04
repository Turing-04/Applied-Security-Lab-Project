#!/bin/bash


# define cron job
CRON_JOB="0 1 * * * /home/ca-server/scripts/backup_ca_config.sh >> /var/log/duplicity.log 2>&1"

# check if job already exists
( crontab -l | grep -q "$CRON_JOB" ) && echo "Cron job already exists" && exit

# add the job to the crontab
( crontab -l 2>/dev/null; echo "$CRON_JOB" ) | crontab -

echo "cron job added successfully."
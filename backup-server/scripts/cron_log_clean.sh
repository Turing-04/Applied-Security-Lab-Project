find /backup -mindepth 1 -type d -exec sh -c 'find "$0/logs" -type d -mmin +1 -delete' {} \;

#-mtime +14

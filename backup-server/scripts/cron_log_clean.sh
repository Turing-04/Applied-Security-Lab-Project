find /backup -type d -name logs -exec sh -c 'find "$0" -mindepth 1 -maxdepth 1 -type d -mtime +14 | xargs rm -r' {} \;

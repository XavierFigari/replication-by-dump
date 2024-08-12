#!/usr/bin/bash

set -x

# Create a backup directory
[[ -d /data/backup ]] || mkdir -p /data/backup

# Dump all databases
/usr/bin/mariadb-dump -v --user=root --password=toto --lock-tables --all-databases > /data/backup/dbs.sql



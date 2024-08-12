#!/usr/bin/bash

set -x

# Restore all databases
/usr/bin/mariadb --user=root --password=toto < /data/backup/dbs.sql

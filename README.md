mysqlbkup
=========

Lightweight MySQL backup script in BASH

This could be the leanest MySQL backup on the entire Web!
In less than 5 minutes backup your databases,
with daily backups on any *nix server with mysqldump.

Instructions
------------
1. Download the script, I recommend installing it somewhere like */usr/local/bin*
2. Set permissions & ownership accordingly
3. Configure the script's database and various other parameters (see *Configuration* below)
4. Setup a CRON job

Configuration
-------------
**Database**
`USER` - The database username
`PASS` - The database password
`HOST` - The database host (default 127.0.0.1)

**Backup**
`BACKUP_DIR`  - The directory where backups are written
`MAX_BACKUPS` - Number of backups per db (default 3)

CRON
----
The cron is simple, just schedule it once per day;
here you can see us redirecting STDOUT to a log file too
    ## mysql backups --------------------------------------
    1 2 * * * /usr/local/bin/mxnmysqldump >> /var/log/db-backup.log

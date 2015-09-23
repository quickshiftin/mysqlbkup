mysqlbkup
=========

Lightweight MySQL backup script to backup all your MySQL databases every night.

In a matter of minutes you can setup nightly backups of your MySQL databases on
any Linux server with mysqldump and standard GNU utilities.

Instructions
------------
1. Download the script, I recommend installing it somewhere like `/usr/local/bin`
2. Set permissions & ownership accordingly
3. Configure database and backup parameters (see **[Configuration](https://github.com/quickshiftin/mysqlbkup/edit/master/README.md#configuration)** below)
4. Setup a CRON job (see **[CRON](https://github.com/quickshiftin/mysqlbkup/edit/master/README.md#cron)** below)

Configuration
-------------
**Database Settings**

`$USER` - The database username

`$PASS` - The database password

`$HOST` - The database host (default 127.0.0.1)

**Backup Settings**

`$BACKUP_DIR`  - The directory where backups are written

`$MAX_BACKUPS` - Number of backups per database (default 3)

**Compression Settings**

`$BKUP_BIN` - The binary used to compress mysqldump files

`$BKUP_EXT` - The extension used for compressed backup files

The default compression program is `gzip` and the default extension is _.gz_.
You may change these to any program and extension you wish, in which case take note the various examples below will have different extensions accordingly.

CRON
----
The cron is simple, just schedule it once per day.

Here we redirect *STDOUT* to a log file and *STDERR* to a separate log file.

    ## mysql backups --------------------------------------
    1 2 * * * /usr/local/bin/mysqlbkup.sh 1>> /var/log/mysqlbkup.log 2>>/var/log/mysqlbkup-err.log
    
What it does
------------
The script will create directories beneath `$BACKUP_DIR`, named after the database.
Beneath there, gzip files are created for each day the database is backed up.  There
will be at most `$MAX_BACKUPS` backup files for each database.

    /var/db-backups/my_db/
    2013-02-10-my_db.sql.gz  2013-02-11-my_db.sql.gz  2013-02-12-my_db.sql.gz

Retrieving a backup
-------------------
Just drill down into the directory of the database you desire to restore
(or copy to another location). Take the prior example for instance. Suppose you wish to
unpack it in your home directory and view the contents of the database. You simply copy
and `gunzip` the file.

    # Copy the database backup to your home directory
    cp /var/db-backups/my_db/2013-02-12-my_db.sql.gz ~
    # Unpack the database
    gunzip ~/2013-02-12-my_db.sql.gz

At this point `~/2013-02-12-my_db.sql` is available as a normal plain text SQL file.

Restoring a backup
------------------
Restore an unzipped SQL file:

    mysql -h [host] -u [uname] -p[pass] [dbname] < [backupfile.sql]

Restore a zipped SQL file:

    gunzip < [backupfile.sql.gz] | mysql -h [host] -u [uname] -p[pass] [dbname]

Requirements
------------
`mysql` & `mysqldump` as well as GNU versions of the following programs
`date`, `gzip`, `head`, `hostname`, `ls`, `rm`, `sed`, `tr`, `wc`

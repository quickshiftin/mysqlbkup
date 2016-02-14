mysqlbkup
=========

Lightweight MySQL backup script to backup all your MySQL databases every night.

In a matter of minutes you can setup nightly backups of your MySQL databases on
any Linux server with mysqldump and standard GNU utilities.

Instructions
------------
1. Download the package
2. Run the installer via sudo - `sudo ./install`
3. Configure database and backup parameters (see **[Configuration](https://github.com/quickshiftin/mysqlbkup/edit/master/README.md#configuration)** below)
4. Setup a CRON job (see **[CRON](https://github.com/quickshiftin/mysqlbkup/edit/master/README.md#cron)** below)

Configuration
-------------
**Database Settings**

These are configured in /etc/mysqlbkup.cnf. Editing this file is similar to /etc/my.cnf.

There are sensible defaults for mysqldump parameters, but you may adjust them to your needs.

**Backup Settings**

These are configured in /etc/mysqlbkup.config

`$BACKUP_DIR`  - The directory where backups are written

`$MAX_BACKUPS` - Number of backups per database (default 3)

**Compression Settings**

These are configured in /etc/mysqlbkup.config

`$BKUP_BIN` - The binary used to compress mysqldump files

`$BKUP_EXT` - The extension used for compressed backup files

The default compression program is `gzip` and the default extension is _.gz_.
You may change these to any program and extension you wish, in which case take note the various examples below will have different extensions accordingly.

**Database filter Setting**

These are configured in /etc/mysqlbkup.config

`$DB_EXCLUDE_FILTER` - Filter to exclude databases from the backup (see [Excluding databases from backup](https://github.com/quickshiftin/mysqlbkup/edit/master/README.md#user-content-excluding-databases-from-backup) below)

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
    
Excluding databases from backup
-------------------------------
The filter string is space-separated list of entries that indicate databases to exclude. You may do an exact match such as
```
DB_EXCLUDE_FILTER='my_db'
```
By default excluding filter entries use [BASH pattern matching](http://www.gnu.org/software/bash/manual/bash.html#Pattern-Matching). So you might test for a prefix in the database name with a filter like this
```
DB_EXCLUDE_FILTER='wp_*'
```
If BASH pattern matching isn't good enough for some reason, you may alternatively use [POSIX regular expressions](http://www.regular-expressions.info/posix.html) by prefixing your entry with a tilde. For example
```
DB_EXCLUDE_FILTER='~.*_test'
```
Again, these are space-separated entries and you can mix and match, so to include all 3 of the examples in one filter
```
DB_EXCLUDE_FILTER='my_db wp_* ~.*_test'
```

Requirements
------------
`mysql` & `mysqldump` as well as GNU versions of the following programs
`date`, `gzip`, `head`, `hostname`, `ls`, `rm`, `tr`, `wc`

If you override `gzip` using the `$BKUP_BIN` option, the binary you choose must be installed and will be checked during script execution.

Dry Run
-------
To test the script's configuration you may invoke it passing _'dry'_ as the first argument.
```
mysqlbkup.sh dry
```

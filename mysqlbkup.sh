#!/bin/bash
# --------------------------------------------------------------------------------
# mysqlbkup
# (c) Nathan Nobbe 2014
# http://quickshiftin.com
# quickshiftin@gmail.com
#
# A simple MySQL backup script in BASH.
#
# All it does is loop over every database and create a backup
# file.  Every database has its own direcotry beneath the root
# backup directory, $BACKUP_DIR.
#
# We're using gzip compression on each backup file and
# labeling backup files by date.  The number of backup files
# per db is controlled by $MAX_BACKUPS.
#
# The script is intended to be run by a cron job.  It echos
# messages to STDOUT which can be redirected to a file for
# simple logging. 
# --------------------------------------------------------------------------------

platform='unknown'
uname=`uname`
if [[ "$uname" == 'Linux' ]]; then
   platform='linux'
elif [[ "$uname" == 'FreeBSD' ]]; then
   platform='freebsd'
fi

# mysql server info ------------------------------------------
USER=
PASS=
HOST=127.0.0.1

# additional config ------------------------------------------
BACKUP_DIR=
MAX_BACKUPS=3

# Databases to ignore
# This is a space separated list.
# Each entry supports bash pattern matching by default.
# You may use POSIX regular expressions for a given entry by prefixing it with a tilde.
DB_EXCLUDE_FILTER=''

# Compression library
BKUP_BIN=gzip # Change this to xz if you wish, for tighter compression
BKUP_EXT=gz   # Change this to xz if you wish, for tighter compression

# validation -------------------------------------------------
# @note We purposely allow blank passwords on purpose
if [ -z "$USER" ]; then
    echo 'Username not set in configuration.' 1>&2
    exit 1
fi

if [ -z "$HOST" ]; then
    echo "Host not set in configuration." 1>&2
    exit 2
fi

if [ -z "$BACKUP_DIR" ]; then
    echo 'Backup directory not set in configuration.' 1>&2
    exit 3
fi

if [ -z "$MAX_BACKUPS" ]; then
    echo 'Max backups not configured.' 1>&2
    exit 4
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory $BACKUP_DIR does not exist." 1>&2
    exit 5
fi

# Check for external dependencies, bail with an error message if any are missing
for program in date $BKUP_BIN head hostname ls mysql mysqldump rm sed tr wc
do
    which $program 1>/dev/null 2>/dev/null
    if [ $? -gt 0 ]; then
        echo "External dependency $program not found or not in $PATH" 1>&2
        exit 6
    fi
done

# the date is used for backup file names
date=$(date +%F)

# get the list of dbs to backup, may as well just hit them all..
dbs=$(echo 'show databases' | mysql --host="$HOST" --user="$USER" --password="$PASS")

# @note Crude handling for OSX,
#       Maybe better to test sed itself rather than infer from OS
if [ $platform == 'linux' ]; then
    dbs=$(echo $dbs | sed -r 's/(Database |information_schema |performance_schema )//g')
else
    dbs=$(echo $dbs | sed -E 's/(Database |information_schema |performance_schema )//g')
fi

echo "== Running $0 on $(hostname) - $date =="; echo

# loop over the list of databases
for db in $dbs
do
    # Check to see if the current database should be skipped
    skip='';
    for filter in $DB_EXCLUDE_FILTER; do
        real_filter="${filter:1}"

        # default to bash pattern matching
        # with support for regular expression matching instead
        match_type='='
        if [ "${filter:0:1}" == '~' ]; then
            match_type='=~'
        fi

        cmd='if [[ "'"$db"'" '"$match_type"' '"$filter"' ]]; then echo skip; fi;';
        skip=$(bash -c "$cmd");

        # Skip this database if
        if [ "$skip" == skip ]; then
            continue 2;
        fi
    done;

	backupDir="$BACKUP_DIR/$db"    # full path to the backup dir for $db
	backupFile="$date-$db.sql.$BKUP_EXT"  # filename of backup for $db & $date

	echo "Backing up $db into $backupDir"

  # each db gets its own directory
	if [ ! -d "$backupDir" ]; then
    # create the backup dir for $db if it doesn't exist
		echo "Creating directory $backupDir"
		mkdir -p "$backupDir"
	else
    # nuke any backups beyond $MAX_BACKUPS
		numBackups=$(ls -1lt "$backupDir"/*."$BKUP_EXT" | wc -l) # count the number of existing backups for $db
		if [ -z "$numBackups" ]; then numBackups=0; fi

		if [ "$numBackups" -gt "$MAX_BACKUPS" ]; then
      # how many files to nuke
			((numFilesToNuke = "$numBackups - $MAX_BACKUPS + 1"))
      # actual files to nuke
			filesToNuke=$(ls -1rt "$backupDir"/*."$BKUP_EXT" | head -n "$numFilesToNuke" | tr '\n' ' ')

			echo "Nuking files $filesToNuke"
			rm $filesToNuke
		fi
	fi

	# create the backup for $db
	echo "Running: mysqldump --force --opt --routines --triggers --max_allowed_packet=250M --user=$USER --password=******** -H $HOST $db | $BKUP_BIN > $backupDir/$backupFile"
	mysqldump --force --opt --routines --triggers --max_allowed_packet=250M --user="$USER" --password="$PASS" --host="$HOST" "$db" | $BKUP_BIN > "$backupDir/$backupFile"
	echo
done

echo "Finished running - $date"; echo

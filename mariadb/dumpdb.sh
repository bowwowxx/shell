#!/bin/bash
# dump mysql db by andy

MyUSER="xx"
MyPASS="xx"
MyHOST="localhost"

MYSQL="/usr/local/mysql/bin/mysql"
MYSQLDUMP="/usr/local/mysql/bin/mysqldump"
MYSQLOPTIONS="--defaults-file=/usr/local/mariadb/my-mariadb.cnf"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"

# Backup Dest directory, change this if you have someother location
DEST="./"

# Main directory where backup will be stored
MBD="$DEST/dumpdb"

# Get hostname
HOST="$(hostname)"

# Get data in dd-mm-yyyy format
NOW="$(date +"%d-%m-%Y")"

# File to store current backup file
FILE=""
# Store list of databases
DBS=""

# DO NOT BACKUP these databases
ExceptionsList="information_schema performance_schema mysql"

[ ! -d $MBD ] && mkdir -p $MBD || :

# Only root can access it!
# $CHOWN 0.0 -R $DEST
# $CHMOD 0600 $DEST

# Get all database list first
echo "$MYSQL $MYSQLOPTIONS -u $MyUSER -p$MyPASS -h $MyHOST -Bse 'show databases;'"
DBS="$($MYSQL $MYSQLOPTIONS -u $MyUSER -p$MyPASS -h $MyHOST -Bse 'show databases;')"


# do all inone job in pipe,
for db in $DBS
do
    skipdb=-1
    if [ "$ExceptionsList" != "" ];
    then
	for i in $ExceptionsList
	do
	    [ "$db" == "$i" ] && skipdb=1 || :
	done
    fi

    if [ "$skipdb" == "-1" ] ; then
      #restore database name: xxx-tmp
	    #FILE="$MBD/$db-tmp.sql.gz"

     #restore database name: over-write old db
      FILE="$MBD/$db.sql.gz"

     $MYSQLDUMP $MYSQLOPTIONS -u $MyUSER -p$MyPASS -h $MyHOST $db | $GZIP -9 > $FILE
    fi
done
tar -cvf $MBD.tar $MBD
rm -rf $MBD

#GCS Link
gcslink=$(curl "http://xxx/signedurl/nas?request=put")
echo $gcslink
curl -v -k -H 'Content-Type: application/octet-stream' -T $MBD.tar "$gcslink"
rm -rf $MBD.tar

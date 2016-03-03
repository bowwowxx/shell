#!/bin/bash
# restore mysql db by andy

MyUSER="xx"
MyPASS="xx"
MyHOST="localhost"

MYSQL="/usr/local/mysql/bin/mysql"
MYSQLADMIN="/usr/local/mysql/bin/mysqladmin"
MYSQLOPTIONS="--defaults-file=/usr/local/mariadb/my-mariadb.cnf"

# Main directory where backup will be stored
MBD="dumpdb"
gcslink=$(curl "http://xx/signedurl/nas?request=get")
echo $gcslink
curl -v -k -H 'Content-Type: application/octet-stream' -o $MBD.tar "$gcslink"

tar xvf $MBD.tar

# Extract files from .gz
function gzip_extract {

  for filename in $MBD/*.gz
    do
      echo "extracting $filename"
      gzip -d -f $filename
    done
}

# Look for sql.gz files
if [ "$(ls -A $MBD/*.gz 2> /dev/null)" ]  ; then
  echo "sql.gz files found extracting..."
  gzip_extract
else
  echo "No .gz files found"
fi

# Exit when folder doesn't have .sql files
if [ "$(ls -A $MBD/*.sql 2> /dev/null)" == 0 ]; then
  echo "No *.sql files found"
  exit 0
fi

# Get all database list first
DBS="$($MYSQL $MYSQLOPTIONS -u $MyUSER -p$MyPASS -h $MyHOST -Bse 'show databases;')"

echo "These are the current existing Databases:"

# Ignore list, won't restore the following list of DB:
ExceptionsList="information_schema performance_schema"


# Restore DBs:
allsqlfile=$(ls -A $MBD 3> /dev/null)

for filename in $allsqlfile;
do
  dbname=${filename%.sql}

  skipdb=-1
  if [ "$ExceptionsList" != "" ]; then
    for ignore in $ExceptionsList
    do
        [ "$dbname" == "$ignore" ] && skipdb=1 || :

    done
  fi

  # If not in ignore list, restore
  if [ "$skipdb" == "-1" ] ; then

    skip_create=-1
    for existing in $DBS
    do
      #echo "Checking database: $dbname to $existing"
      [ "$dbname" == "$existing" ] && skip_create=1 || :
    done

    if [ "$skip_create" ==  "1" ] ; then
      echo "Database: $dbname already exist, skiping create"
    else
      echo "Creating DB: $dbname"
      $MYSQLADMIN $MYSQLOPTIONS create $dbname -u $MyUSER -p$MyPASS
    fi

    echo "Importing DB: $dbname from $filename"
      $MYSQL $MYSQLOPTIONS $dbname < $MBD/$filename -u $MyUSER -p$MyPASS
  fi
done
rm -rf $MBD $MBD.tar

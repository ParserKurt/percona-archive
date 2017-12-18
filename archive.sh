#!/bin/bash
JQ=/usr/local/bin/jq
env="config/environment/development.json"

host=($(jq -r '.host' $env))
database=($(jq -r '.database' $env))
table=($(jq -r '.table' $env))
user=($(jq -r '.user' $env))
password=($(jq -r '.password' $env))
file=($(jq -r '.file' $env))
condition_archive=($(jq -r '.condition_archive' $env))
condition_purge=($(jq -r '.condition_purge' $env))
days_archive=($(jq -r '.days_archive' $env))
days_purge=($(jq -r '.days_purge' $env))
getArray() {
    array=() # Create array
    while IFS= read -r line # Read a line
    do
        array+=("$line") # Append line to the array
    done < "$1"
}

#execute archive
echo "executing data archiving......."
getArray "config/tables.txt"
for t in "${array[@]}"
    do
#        if [ $t = "api_user" ]
#            then
#                condition_archive="date_created < NOW() - INTERVAL 90 DAY"
#            else
#                condition_archive="timestamp < NOW() - INTERVAL 90 DAY"
#        fi
        condition_archive="timestamp < NOW() - INTERVAL $days_archive DAY"
        echo "archiving $t"
        eval pt-archiver --source h=$host,D=$database,t=$t,p=$password,u=$user --dest h=127.0.0.1,D=hawkeyeBUP --where "'$condition_archive'" --limit 10000 --commit-each --replace  --no-check-charset --no-delete --progress 1 --statistics --why-quit --retries 5 --optimize=s
    done
echo "done archiving"
#execute purge
echo "executing data purging........"
getArray "config/tables.txt"
for t in "${array[@]}"
    do
#         if [ $t = "api_user" ]
#            then
#                condition_purge="date_created < NOW() - INTERVAL 180 DAY"
#            else
#                condition_purge="timestamp < NOW() - INTERVAL 180 DAY"
#         fi
         condition_purge="timestamp < NOW() - INTERVAL $days_purge DAY"
         echo "purging $t"
         eval pt-archiver --source h=$host,D=$database,t=$t,p=$password,u=$user --where "'$condition_purge'" --purge --limit 10000 --commit-each --primary-key-only --no-check-charset --header --statistics --why-quit --retries 5 --optimize=sD
    done
echo "done purging"

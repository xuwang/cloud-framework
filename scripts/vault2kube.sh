#!/bin/bash
# Usage:
#   vault2kube <secret.yml>
# Replace %%vaule-secret-path%% in a kube secret template file with 
# secret value stored at vaule-secret-path

OLDIFS=$IFS
IFS=''
while read line
do
    path=$(echo $line | grep -v '^#' | grep -o -e '%%.*%%' | tr -d '%')
    if [ -z $path ]
    then
        echo $line
    else
        sec=$(vault-read.sh $path | base64 | tr -d '\n')
        echo $line | sed -e "s|%%${path}%%|${sec}|"
    fi
done < "${1:-/dev/stdin}"
IFS=$OLDIFS

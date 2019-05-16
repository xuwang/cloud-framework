#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <vault-secret-path> [<password-length>]"
    echo "You must have the write privilege to <vault-secret-path>"
    exit 1
fi

length=${2:-20}

if vault-read.sh $1 &> /dev/null
then 
    echo "ERROR: $1 has value."
else 
    echo Generate a new password and save to the $1
    pwd=$(pwgen $length 1 | tr -d '\n')
    vault-write.sh $1 $pwd
fi

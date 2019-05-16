#!/usr/bin/env bash

if [ -z $1 ]
then
	echo "Usage bucket-acl.sh <bucket>"
	exit 1
fi

gsutil acl get gs://$1 | jq

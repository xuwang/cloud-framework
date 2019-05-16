#!/bin/bash -e
# Usage:
#   vault-list-users.sh [<userid>]

# include functions
THIS_DIR=$(dirname "$0")
source $THIS_DIR/functions.sh

user=$1
tmpfile=$(mktemp)

function list_aliases() {
  vault list -format json  identity/entity-alias/id  | jq -r '.[]' > $tmpfile
}

function list_all_users() {
  for i in `cat $tmpfile`
  do
    vault read -format=json identity/entity-alias/id/$i  | jq -r '.data.name'
  done
}

function get_user() {
  for i in `cat $tmpfile`
  do
    vault read -format=json identity/entity-alias/id/$i  | \
        jq -r ".data | select(.name==\"$user\")" > $tmpfile.$user
    if [ -s "$tmpfile.$user" ]; then
      cat $tmpfile.$user
      break
    fi
  done
}

# MAIN

if vault token lookup > /dev/null 2>&1 ; then
  admin=$(vault token lookup -format=json | jq -r '.data.display_name')
  echo "Using $admin token to lookup vault users."
else 
  echo "Valid vault token is required. Please run vault login."
  exit 1
fi

list_aliases

if [ ! -z "$user" ]; then
  get_user
else
  list_all_users
fi

rm -rf $tmpfile $tmpfile.$user
 

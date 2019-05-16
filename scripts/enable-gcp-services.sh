#!/usr/bin/env bash

##
## Enable GCP Servies/APIs defined in file $1
## Each line in $1 is a service name to be enabled.
## 

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

function get_enabled_svc() {
  grep -v '^#' $1 | grep -v -e '^$' | render.sh |
  while read -r line; do
    echo $line
  done
}

svc_list=$(get_enabled_svc $1)

if [ ! -z "$svc_list" ]
then
  gcloud services enable --async $svc_list
fi
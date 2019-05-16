#!/bin/bash

###############################################################################
# Delete: Set up a google cloud storage bucket to be an https site
# assumes foundation of create-bucket-site-lb.sh
###############################################################################

THIS_DIR=$(dirname "$0")
DRONE_BASE_DIR="${DRONE_BASE_DIR:-.}"

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

url_map_name=$1
backend_bucket_name=$2
path_matcher_name=$3
app_hostname=$4

# delete host-rule from url-map
if gcloud --format json compute url-maps describe $url_map_name | jq -e ".hostRules |select(.[].hosts[] == \"$app_hostname\")" > /dev/null 2>&1; then
  gcloud -q compute url-maps remove-host-rule $url_map_name --host "$app_hostname" --delete-orphaned-path-matcher
else
  echo "host rule for '$app_hostname' already deleted"
fi

# delete path matcher from url-map
if gcloud --format json compute url-maps describe $url_map_name | jq -e ".pathMatchers[] | select(.name == \"$path_matcher_name\")" > /dev/null 2>&1; then
  gcloud compute url-maps remove-path-matcher $url_map_name --path-matcher-name $path_matcher_name
else
  echo "path matcher '$path_matcher_name' already deleted"
fi

# delete backend bucket
if gcloud beta compute backend-buckets describe $backend_bucket_name > /dev/null 2>&1; then
  gcloud beta -q compute backend-buckets delete $backend_bucket_name
else
  echo backend bucket "'$backend_bucket_name'" already deleted
fi

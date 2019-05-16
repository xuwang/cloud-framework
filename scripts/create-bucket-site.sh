#!/bin/bash

###############################################################################
# Set up a google cloud storage bucket to be an https site
# assumes foundation of create-bucket-site-lb.sh
###############################################################################

THIS_DIR=$(dirname "$0")
DRONE_BASE_DIR="${DRONE_BASE_DIR:-.}"

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

url_map_name=$1
bucket_name=$2
backend_bucket_name=$3
path_matcher_name=$4
app_hostname=$5

# give public access to all files in bucket
gsutil -m acl -r ch -u AllUsers:R gs://$bucket_name
gsutil web set -m index.html -e 404.html gs://$bucket_name

# create backend bucket
if gcloud beta compute backend-buckets describe $backend_bucket_name > /dev/null 2>&1; then
  echo backend bucket "'$backend_bucket_name'" already exists
else
  gcloud beta compute backend-buckets create $backend_bucket_name \
    --gcs-bucket-name $bucket_name
fi

# add path matcher to url-map (and host rule via --new-hosts)
if gcloud --format json compute url-maps describe $url_map_name | jq -e ".pathMatchers[] | select(.name == \"$path_matcher_name\")" > /dev/null 2>&1; then
  echo "path matcher '$path_matcher_name' already exists"
else
  gcloud compute url-maps add-path-matcher $url_map_name --path-matcher-name $path_matcher_name --default-backend-bucket $backend_bucket_name --new-hosts "$app_hostname"
fi

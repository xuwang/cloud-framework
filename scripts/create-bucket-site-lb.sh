#!/bin/bash

###############################################################################
# Create a url-map object, aka L7 load balancer and all necessary scaffolding
# to add an IP and SSL
#
# for now: creates an empty default bucket, since the assumption is that all
# hostnames going through this load balancer have their own default buckets
#
# each site added uses create-bucket-site.sh to do the rest of the work
###############################################################################

THIS_DIR=$(dirname "$0")
DRONE_BASE_DIR="${DRONE_BASE_DIR:-.}"

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

url_map_name=$1
default_bucket_name=$2
default_backend_bucket_name=$3
ssl_certificate_name=$4
ssl_certificate_file=$5
ssl_key_file=$6
target_proxy_name=$7
global_forwarding_rule_name=$8

# TODO: eventually we need to have global default bucket with nice 404 page?
# create default (empty) bucket if one doesn't exist
if gsutil ls gs://$default_bucket_name > /dev/null 2>&1; then
  echo "default bucket '$default_bucket_name' already exists"
else
  gsutil mb gs://$default_bucket_name
fi

# create default backend bucket
if gcloud beta compute backend-buckets describe $default_backend_bucket_name > /dev/null 2>&1; then
  echo default backend bucket "'$default_backend_bucket_name'" already exists
else
  gcloud beta compute backend-buckets create $default_backend_bucket_name \
    --gcs-bucket-name $default_bucket_name
fi

# create the url map
if gcloud compute url-maps describe $url_map_name > /dev/null 2>&1; then
  echo url-map "'$url_map_name'" already exists
else
  gcloud compute url-maps create $url_map_name --default-backend-bucket $default_backend_bucket_name
fi

# upload ssl cert
if gcloud compute ssl-certificates describe $ssl_certificate_name > /dev/null 2>&1; then
  echo "certificate '$ssl_certificate_name' already created"
else
  gcloud compute ssl-certificates create $ssl_certificate_name --certificate $ssl_certificate_file --private-key $ssl_key_file
fi

# create https target proxy
if gcloud compute target-https-proxies describe $target_proxy_name > /dev/null 2>&1; then
  echo "target https proxy '$target_proxy_name' already created"
else
  gcloud compute target-https-proxies create $target_proxy_name --url-map $url_map_name --ssl-certificate $ssl_certificate_name
fi

# create global forwarding rule
if gcloud compute forwarding-rules describe $global_forwarding_rule_name --global > /dev/null 2>&1; then
  echo "global forwarding-rule '$global_forwarding_rule_name' already created"
else
  gcloud compute forwarding-rules create $global_forwarding_rule_name \
    --global --target-https-proxy $target_proxy_name --ports 443
fi

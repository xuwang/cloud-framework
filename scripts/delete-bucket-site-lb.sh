#!/bin/bash

###############################################################################
# Delete a url-map object, aka L7 load balancer and all necessary scaffolding
# to add an IP and SSL
# sets up the foundation for create-bucket-site.sh
###############################################################################

THIS_DIR=$(dirname "$0")
DRONE_BASE_DIR="${DRONE_BASE_DIR:-.}"

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

url_map=$1
default_bucket_name=$2
default_backend_bucket_name=$3
ssl_certificate_name=$4
target_proxy_name=$5
global_forwarding_rule_name=$6

# delete global forwarding rule
if gcloud compute forwarding-rules describe $global_forwarding_rule_name --global > /dev/null 2>&1; then
  gcloud -q compute forwarding-rules delete $global_forwarding_rule_name --global
else
  echo "global forwarding-rule '$global_forwarding_rule_name' already deleted"
fi

# delete https target proxy
if gcloud compute target-https-proxies describe $target_proxy_name > /dev/null 2>&1; then
  gcloud -q compute target-https-proxies delete $target_proxy_name
else
  echo "target https proxy '$target_proxy_name' already deleted"
fi

# delete ssl cert
if gcloud compute ssl-certificates describe $ssl_certificate_name > /dev/null 2>&1; then
  gcloud -q compute ssl-certificates delete $ssl_certificate_name
else
  echo "certificate '$ssl_certificate_name' already deleted"
fi

# delete the url map
if gcloud compute url-maps describe $url_map > /dev/null 2>&1; then
  gcloud -q compute url-maps delete $url_map
else
  echo url-map "'$url_map'" already deleted
fi

# delete default backend bucket
if gcloud beta compute backend-buckets describe $default_backend_bucket_name > /dev/null 2>&1; then
  gcloud beta -q compute backend-buckets delete $default_backend_bucket_name
else
  echo backend bucket "'$default_backend_bucket_name'" already deleted
fi

# delete default bucket
if gsutil ls gs://$default_bucket_name > /dev/null 2>&1; then
  gsutil rm -rf gs://$default_bucket_name
else
  echo "default bucket '$default_bucket_name' already deleted"
fi

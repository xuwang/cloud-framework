#!/bin/bash

###############################################################################
# create gcs storage buckets from storage buckets directory
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

storage_buckets_dir=$1

for storage_bucket_dir in $storage_buckets_dir/*; do
    bucket_file=$storage_bucket_dir/bucket.yaml
    iam_template=$storage_bucket_dir/iam.yaml

    bucket=$(gomplate < $bucket_file | yaml2json.sh)

    bucket_name=$(echo "$bucket" | jq -er .name)
    bucket_location=$(echo "$bucket" | jq -er .location)
    bucket_class=$(echo "$bucket" | jq -er .class)
    bucket_versioning=$(echo "$bucket" | jq -r .versioning)

    # fill in iam template (its a gomplate template)
    iam_file=/tmp/${bucket_name}_iam.json
    gomplate < $iam_template | yaml2json.sh > $iam_file

    if gsutil iam get gs://$bucket_name > /dev/null 2>&1; then
        >&2 echo "bucket '$bucket_name' already exists"
    else
        gsutil mb -c $bucket_class -l $bucket_location -p $GCP_PROJECT_ID gs://$bucket_name
    fi

    if ! [ "$bucket_versioning" = null ]; then
        gsutil versioning set $bucket_versioning gs://$bucket_name
    fi

    gsutil iam set $iam_file gs://$bucket_name
    rm $iam_file
done
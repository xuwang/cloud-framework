#!/bin/bash

###############################################################################
# create service accounts from yaml files in a directory
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

service_accounts_dir=$1

for service_account_file in $service_accounts_dir/*; do
    bucket=$(gomplate < $service_account_file | yaml2json.sh)

    name=$(echo "$bucket" | jq -er .name)
    display_name=$(echo "$bucket" | jq -er '.["display-name"]')

    if gcloud iam service-accounts describe "${name}@${GCP_PROJECT_ID}.iam.gserviceaccount.com" --project $GCP_PROJECT_ID > /dev/null 2>&1; then
        >&2 echo "service account '$name' already exists"
    else
        gcloud iam service-accounts create $name --display-name $display_name --project $GCP_PROJECT_ID
    fi
done
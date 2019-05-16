#!/bin/bash

###############################################################################
# create log metrics given a yaml log metrics definition file
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

metrics_dir=$1

for metrics_file in $metrics_dir/*; do
    metric=$(gomplate < $metrics_file | yaml2json.sh)

    name=$(echo "$metric" | jq -er .name)
    description=$(echo "$metric" | jq -er .description)
    filter=$(echo "$metric" | jq -er .filter)

    if gcloud logging metrics describe $name --project $GCP_PROJECT_ID > /dev/null 2>&1; then
        gcloud logging metrics update $name --description="$description" --log-filter="$filter" --project $GCP_PROJECT_ID
    else
        gcloud logging metrics create $name --description="$description" --log-filter="$filter" --project $GCP_PROJECT_ID
    fi
done



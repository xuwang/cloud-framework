#!/bin/bash

###############################################################################
# create log sinks given a yaml sinks definition file
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

sinks_dir=$1

# alternate project_id to create the bucket in if it doesn't exist, optional
set -u
bucket_project_id=${2:-$GCP_PROJECT_ID}
set +u

for sinks_file in $sinks_dir/*; do
    sink=$(gomplate < $sinks_file | yaml2json.sh)
    name=$(echo "$sink" | jq -er .name)
    dest=$(echo "$sink" | jq -er .destination)

    if filter=$(echo "$sink" | jq -er .filter); then
        filter_arg="--log-filter='$filter'"
    fi

    # create bucket if sink type is bucket
    if [[ $dest == storage.googleapis.com/* ]]; then
        bucket_name=${dest#*/}

        if ! gsutil versioning get gs://${bucket_name} > /dev/null 2>&1; then # check if exists
            gsutil mb -c regional -l $GCP_REGION -p ${bucket_project_id} gs://${bucket_name} 
        fi
    fi

    # create sink (log exporter)
    if gcloud logging sinks describe --project $GCP_PROJECT_ID $name > /dev/null 2>&1; then
        >&2 echo "logging sink ${name} already exists, updating..."
        # do eval since filter arg contains spaces
        eval gcloud -q logging sinks update $name $dest --project $GCP_PROJECT_ID $filter_arg
    else
        eval gcloud -q logging sinks create $name $dest --project $GCP_PROJECT_ID $filter_arg
    fi

    # give sink (log exporter) service account name as owner of bucket
    if [[ $dest == storage.googleapis.com/* ]]; then
        # fetch service account name that will write to bucket
        writer_identity=$(gcloud --format json logging sinks describe $name | jq -er .writerIdentity)

        # add access to bucket via iam
        gsutil iam ch ${writer_identity}:admin gs://${bucket_name}
    fi
done



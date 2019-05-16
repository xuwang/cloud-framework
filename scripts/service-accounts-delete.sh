#!/bin/bash -e
# setup servcie accounts and roles defined in service_accounts_dir/*.json
# Eche file represents a servcie account and it's roles.

# Note: Service account name must be between 6 and 30 characters (inclusive), 
# must begin with a lowercase letter, and consist of lowercase alphanumeric 
# characters that can be separated by hyphens.

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

if [ -z "${GCP_PROJECT_ID}" ]; then
  echo "Missing GCP_PROJECT_ID!"
  exit 1
fi

function delete_servcie_account() {
    name=$(echo $1 | jq -r '.name')
    if [ ! -z "$name" ]
    then
        project_id=$(echo $1 | jq -r '.gcp_project_id')
        [[ -z $project_id ]] || project_id=$GCP_PROJECT_ID

        service_account="${name}@${project_id}.iam.gserviceaccount.com"

        if gcloud iam service-accounts describe "${service_account}" --project $project_id > /dev/null 2>&1
        then
            gcloud iam service-accounts delete "${service_account}" --project $project_id
        else          
            >&2 echo "Service account '$service_account' does not exist."
        fi
    fi
}
service_accounts_dir=$1

for filename in $service_accounts_dir/*.json
do
    service_account_json="$(cat $filename | render.sh )"
    delete_servcie_account "$service_account_json"
done
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

function create_servcie_account() {
    name=$1
    project_id=$2
    service_account_json=$3
    display_name=$(echo $service_account_json | jq -r '.display_name') 
    is_null_or_empty $display_name && display_name="$name service account"
    service_account="${name}@${project_id}.iam.gserviceaccount.com"

    if gcloud iam service-accounts describe "${service_account}" --project $project_id > /dev/null 2>&1; then
        >&2 echo "service account '$name' already exists"
    else
        gcloud iam service-accounts create "$name" --display-name "$display_name" --project $project_id
    fi
}

function binding_roles() {
    name=$1
    project_id=$2
    service_account_json=$3
    service_account="${name}@${project_id}.iam.gserviceaccount.com"

    for role in $(echo $service_account_json| jq -r 'select(.roles != null) | .roles[]')
    do
        echo "Binding ${service_account} to ${role}"
        gcloud projects add-iam-policy-binding "${project_id}" \
            --member "serviceAccount:${service_account}" \
            --role "${role}" \
            --user-output-enabled=false
    done
}

service_accounts_dir=$1

for filename in $service_accounts_dir/*.json
do
    service_account_json="$(cat $filename | render.sh)"
    name=$(echo $service_account_json | jq -r '.name')
    if ! is_null_or_empty $name
    then
        project_id=$(echo $service_account_json | jq -r '.gcp_project_id')
        is_null_or_empty $project_id && project_id=$GCP_PROJECT_ID

        create_servcie_account $name $project_id "$service_account_json"
        binding_roles $name $project_id "$service_account_json"
    fi
done
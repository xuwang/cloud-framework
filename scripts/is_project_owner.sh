#!/bin/bash -e

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

user=${1:-$USER}
project=${2:-$GCP_PROJECT_ID}

ok=$(gcloud projects get-iam-policy \
    $project --format json \
    | jq --arg u "$user" '.bindings[] | select(.members[] | contains($u)) | .role|contains("roles/owner")')

if [ "$ok" = "true" ]
then 
    echo true
    exit 0
else
    echo false
    exit 1
fi
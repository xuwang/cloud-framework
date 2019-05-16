#!/bin/bash

###############################################################################
# create kms keyrings/keys & set iam privileges for those keys
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

keyrings_dir=$1

for keyring_dir in $keyrings_dir/*; do
    keyring_file=$keyring_dir/keyring.yaml
    iam_template=$keyring_dir/iam.yaml
    
    # fill in keyring file (also a gomplate template)
    keyring=$(gomplate < $keyring_file | yaml2json.sh)

    keyring_name=$(echo "$keyring" | jq -er .name)

    keyring_location=$(echo "$keyring" | jq -er .location)

    if ! [ -z keyring_location ]
    then
        keyring_location=$GCP_REGION
    fi

    # fill in iam template (its a gomplate template)
    iam_file=/tmp/${keyring_name}_iam.yaml
    gomplate < $iam_template > $iam_file

    if gcloud kms keyrings describe $keyring_name --location $keyring_location --project $GCP_PROJECT_ID > /dev/null 2>&1; then
        2>&1 echo "keyring '$keyring_name' already exists"
    else
        gcloud kms keyrings create $keyring_name --location $keyring_location --project $GCP_PROJECT_ID
    fi

    echo "$keyring" | jq -ec .keys[] | while read -r key; do
        key_name=$(echo "$key" | jq -er .name)
        key_purpose=$(echo "$key" | jq -er .purpose)

        if gcloud kms keys describe $key_name --keyring $keyring_name --location $keyring_location --project $GCP_PROJECT_ID > /dev/null 2>&1; then
            2>&1 echo "key '$key_name' in keyring '$keyring_name' already exists"
        else
            gcloud kms keys create $key_name --location $keyring_location --keyring $keyring_name --purpose $key_purpose --project $GCP_PROJECT_ID
        fi

        # for now just apply keyring iam to all keys
        gcloud kms keys set-iam-policy $key_name $iam_file --location $keyring_location --keyring $keyring_name --project $GCP_PROJECT_ID
    done

    # clean up tmp iam file
    rm -f $iam_file
done



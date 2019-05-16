#!/bin/bash -e
# setup kms keyring/keys defined in kms_dir/*.json
# Eche file represents a keyring.

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

function add_keyring_policy() {
    keyring_name=$1
    locaion=$2
    policy_json=$(echo $3 | base64 --decode)
    member=$(echo $policy_json| jq -r ".member")

    if ! is_null_or_empty $member
    then
        role=$(echo $policy_json | jq -r ".role")
        is_null_or_empty role && role="cloudkms.cryptoKeyEncrypterDecrypter"
        
        gcloud kms keyring add-iam-policy-binding "$keyring_name" \
            --location "$location" \
            --member "$member" \
            --role "$role"
    fi
}

function add_key_policy() {
    keyring_name=$1
    key_name=$2
    locaion=$3
    policy_json=$(echo $4 | base64 --decode)
    member=$(echo $policy_json | jq -r ".member")

    if ! is_null_or_empty $member
    then
        role=$(echo $policy_json | jq -r ".role")
        is_null_or_empty role && role="cloudkms.cryptoKeyEncrypterDecrypter"
        gcloud kms keys add-iam-policy-binding "$key_name" \
            --location "$location" \
            --keyring "$keyring_name" \
            --member "$member" \
            --role "$role"
    fi
}

function create_keyring() {
    keyring_json=$1
    keyring_name=$(echo $keyring_json | jq -r '.keyring_name')

    if ! is_null_or_empty $keyring_name
    then
        location=$(echo $keyring_json | jq -r '.location') 
        is_null_or_empty $location && location="global"

        # Create keyring if not exists
        if gcloud kms keyrings describe ${keyring_name} \
            --location $location  > /dev/null 2>&1
        then
            2>&1 echo "keyring ${keyring_name} already exists"
        else
            gcloud kms keyrings create ${keyring_name} --location $location
        fi
        
        # Create all keys on the keyring
        for key in $(echo $keyring_json | jq -r 'select(.keys != null) |.keys[] | @base64')
        do
            create_key $keyring_name $location $key
        done

        # Add keyring polices
        for policy in $(echo $keyring_json | jq -r 'select(.policies != null) | .policies[] | @base64')
        do
            add_keyring_policy $keyring_name $location $policy
        done
    fi
}


function create_key() {
        keyring_name=$1
        keyring_location=$2
        key_json=$(echo $3 | base64 --decode)
        key_name=$(echo $key_json | jq -r ".key_name")

        # Create key on the keyring
        if ! is_null_or_empty $key_name
        then
            key_location=$(echo $key_json | jq -r '.location') 
            is_null_or_empty $key_location && key_location=$keyring_location 

            purpose=$(echo $key_json | jq -r '.purpose') 
            is_null_or_empty $purpose && purpose="encryption"
            
            if gcloud kms keys describe ${key_name} \
                --keyring $keyring_name \
                --location $location  > /dev/null 2>&1
            then
                2>&1 echo "key ${key_name} in keyring ${keyring_name} already exists"
            else
                gcloud kms keys create $key_name \
                    --location "$key_location" \
                    --keyring "$keyring_name" \
                    --purpose "$purpose"
            fi

            # add key policies
            for policy in $(echo $key_json | jq -r 'select(.policies != null) | .policies[] | @base64')
            do
                add_key_policy $keyring_name $key_name $key_location $policy
            done
        fi
}

kms_dir=$1

for filename in $kms_dir/*.json; do
    keyring_json="$(cat $filename | render.sh)"
    create_keyring "$keyring_json"
done

#!/bin/bash -e
# setup storage buckets defined in buckets_dir/*.json
# Eche file defines one bucket.

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

function set_bucket_acl() {
    bucket=$1
    bucket_json=$2
    bucket_acls=$(echo $bucket_json | jq -r 'select(.acl.bucket_acls != null) | .acl.bucket_acls[]')
    users=$(echo $bucket_json | jq -r 'select(.acl.users != null) | .acl.users[]')
    groups=$(echo $bucket_json | jq -r 'select(.acl.groups != null) | .acl.groups[]')
    projects=$(echo $bucket_json | jq -r 'select(.acl.projects != null) | .acl.projects[]')

    for a in $bucket_acls
    do
        echo "Set bucket ACL $a ..."
        gsutil -m acl set $a $bucket
    done

    for u in $users
    do
        echo "Set user ACL $u ..."
        gsutil -m acl ch -u $u $bucket
    done

    for g in $groups
    do
        echo "Set group ACL $g ..."
        gsutil -m acl ch -g $g $bucket
    done
    
    for p in $projects
    do
        echo "Set project ACL $p ..."
        gsutil -m acl ch -p $p $bucket
    done
}

function set_lifecycle_policy() {
    bucket=$1
    bucket_json=$2
    policy_json=$(echo $bucket_json | jq -r '.livecycle_policy')

    if ! is_null_or_empty $policy_json
    then
        policy_file=$(mktemp)
        echo $policy_json > $policy_file
        gsutil lifecycle set $policy_file $bucket
        rm -f $policy_file
    fi
}

function create_bucket() {
    bucket=$1
    bucket_json=$2

    # Create bucket if not exists
    if gsutil ls -p ${GCP_PROJECT_ID} $bucket &> /dev/null
    then
        echo "Storage bucket $bucket exists."
    else
        echo "Creating storage bucket $bucket ..."

        class=$(echo $bucket_json | jq -r '.class') 
        if is_null_or_empty $class
        then
            class_opt=" "
        else
            class_opt="-c $class"
        fi

        # see https://cloud.google.com/storage/docs/bucket-locations
        location=$(echo $bucket_json | jq -r '.location') 
        if is_null_or_empty $location
        then
            location_opt=" "
        else
            location_opt="-l $location"
        fi

        gsutil mb -p ${GCP_PROJECT_ID} $class_opt $location_opt $bucket
    fi
}

bucket_dir=$1

for filename in $bucket_dir/*.json; do
    bucket_json="$(cat $filename | render.sh)"
    bucket_name=$(echo $bucket_json | jq -r '.name')

    if ! is_null_or_empty $bucket_name
    then
        bucket="gs://$bucket_name"
        create_bucket $bucket "$bucket_json"
        set_bucket_acl $bucket "$bucket_json"
        set_lifecycle_policy $bucket "$bucket_json"
    fi
done

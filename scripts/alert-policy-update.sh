#!/bin/bash

###############################################################################
# create or update alert policies defined in json format
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

template_dir=$1

for policy_file in $template_dir/*.json; do
    policy=$(cat $policy_file | render.sh )
    name=$(echo "$policy" | jq -er .displayName)
    policy_id=$(gcloud alpha monitoring policies list --format=json | \
        jq --arg KEY "$name" -r '.[] | select(.displayName==$KEY)|.name' )
    if [ -z "$policy_id" ]; then
        echo "Try creating alert policy $name"
        cat $policy_file | render.sh | gcloud alpha monitoring policies create --policy-from-file -
    else
        echo "Try updating alert policy $name"
        cat $policy_file | render.sh | gcloud alpha monitoring policies update $policy_id --policy-from-file - 
    fi  
done




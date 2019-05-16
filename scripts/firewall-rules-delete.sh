#!/bin/bash

###############################################################################
# delete firewall rules from delete.yaml file (a simple list of fw rules to delete)
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

delete_rules_file=$1

gomplate < $delete_rules_file | yaml2json.sh | jq -er .rules[] | while read -r rule_name; do
    if gcloud compute firewall-rules describe $rule_name --project ${GCP_PROJECT_ID} > /dev/null 2>&1; then
        gcloud -q compute firewall-rules delete $rule_name --project ${GCP_PROJECT_ID}
    fi
done
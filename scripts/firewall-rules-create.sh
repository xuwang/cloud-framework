
#!/bin/bash

###############################################################################
# create firewall rules from firewall-rules directory
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

firewall_rules_dir=$1

for rule_file in $firewall_rules_dir/*; do
    rule_file_rel=${rule_file%.yaml}
    rule_name=${rule_file_rel##*/}
    if gcloud compute firewall-rules describe $rule_name --project ${GCP_PROJECT_ID} > /dev/null 2>&1; then
        eval gcloud compute firewall-rules update $rule_name $(yaml-to-args.sh $rule_file direction action) --project $GCP_PROJECT_ID
    else
        eval gcloud compute firewall-rules create $rule_name $(yaml-to-args.sh $rule_file) --project $GCP_PROJECT_ID
    fi
done
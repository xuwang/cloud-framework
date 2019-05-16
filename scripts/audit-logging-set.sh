
#!/bin/bash

###############################################################################
# Sets audit logging for a GCP project w/ file of format:
# auditConfigs:
# - auditLogConfigs:
#   - logType: DATA_READ
#   - logType: DATA_WRITE
#   service: cloudsql.googleapis.com
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

gcloud projects get-iam-policy --format json $GCP_PROJECT_ID | \
    jq -e --argjson audit "$(${SCRIPTS_DIR}/yaml2json.sh < $1 | jq -ec .auditConfigs)" '.auditConfigs=$audit' \
    > /tmp/iam-policy.json

gcloud projects set-iam-policy $GCP_PROJECT_ID /tmp/iam-policy.json

rm -f /tmp/iam-policy.json
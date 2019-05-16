#!/bin/bash

###############################################################################
# Creates a cloud sql instance
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

instance_prefix=${db_instance_prefix}
tier=${db_tier}
db_version=${db_version}

# failover not required
set +u
region=${db_region:-$GCP_REGION}
storage_size=${db_size:-10GB}
failover_instance_prefix=${db_failover_instance_prefix}
set -u

# these parameters are required if failover instance prefix was specified
if ! [ -z "$failover_instance_prefix" ]; then
  failover_zone=${db_failover_zone}
  failover_tier=${db_failover_tier}
fi

instance_name=$($THIS_DIR/cloud-sql-prefix-to-name.sh $instance_prefix)

echo
echo "restoring master Cloud SQL instance '$instance_name' to the following backup:"
backup_object=$(gcloud --format json beta sql backups list --instance $instance_name \
	 	 --sort-by windowStartTime | jq -ec .[-1])
echo $backup_object | jq
echo

# first delete the failover replica
if [ ! -z "$failover_instance_prefix" ]; then
  old_failover_instance_name=$($THIS_DIR/cloud-sql-prefix-to-name.sh $failover_instance_prefix)

  echo "PRE-ROLLBACK: deleting Cloud SQL FAILOVER replica instance '${old_failover_instance_name}' to rollback master instance"
  gcloud sql instances delete $old_failover_instance_name
fi

echo "ROLLBACK: restoring master Cloud SQL instance '${instance_name}' to backup:"
backup_id=$(echo $backup_object | jq -er .id)
gcloud beta sql backups restore --restore-instance=$instance_name $backup_id

if [ ! -z "$failover_instance_prefix" ]; then
  new_failover_instance_name="${failover_instance_prefix}-$(date +%s)"

  echo "POST-ROLLBACK: recreating failover replica instance w/ new name '${new_failover_instance_name}'"
  gcloud beta sql instances create \
    --region $region \
    --database-version $db_version \
    --gce-zone $failover_zone \
    --tier $failover_tier \
    --storage-auto-increase \
    --storage-size $storage_size \
    --master-instance-name $instance_name \
    --replica-type FAILOVER \
    $new_failover_instance_name
fi

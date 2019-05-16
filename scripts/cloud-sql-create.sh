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
db_version=${db_version}
database_name=${db_name}
database_user=${db_user}
root_password=${db_root_password}
user_password=${db_user_password}

# optional vars
set +u
zone=${db_zone:-$GCP_ZONE}
region=${db_region:-$GCP_REGION}
tier=${db_tier:-db-n1-standard-1}
storage_size=${db_size:-10GB}
maintenance_window_hour=${db_maintenance_hour:-8} # 12am
maintenance_day=${db_maintenance_day:-SUN}
backup_time=${db_backup_time:-9:00} # 1 am
failover_instance_prefix=${db_failover_instance_prefix}
set -u

# these parameters are required if failover instance prefix was specified
if ! [ -z "$failover_instance_prefix" ]; then
  failover_zone=${db_failover_zone}
  failover_tier=${db_failover_tier}
fi

# is there a cloud sql instance with given prefix?
# cloud sql prefix to name returns err code 1 for not exists, 2 for more than one SQL instance matching
err_code=0
$THIS_DIR/cloud-sql-prefix-to-name.sh $instance_prefix > /dev/null 2>&1 || err_code=$?

if [ $err_code = 1 ]; then
  # we need to put the timestamp at the end of the DB name since the naming
  # collision issue
  instance_name="${instance_prefix}-$(date +%s)"

  if [ -z $backup_time ]; then
    backup_args=
  else
    backup_args="--enable-bin-log --backup --backup-start-time $backup_time"
  fi

  # create main db
 gcloud sql instances create $instance_name \
    $backup_args \
    --region $region \
    --database-version $db_version \
    --gce-zone $zone \
    --tier $tier \
    --storage-size $storage_size \
    --storage-auto-increase \
    --maintenance-window-hour $maintenance_window_hour \
    --maintenance-window-day $maintenance_day

  # create failover replica if specified
  if [ ! -z "$failover_instance_prefix" ]; then
    failover_instance_name="${failover_instance_prefix}-$(date +%s)"
    # create failover db, use same code for recreate for db rollback
    gcloud sql instances create $failover_instance_name \
      --region $region \
      --database-version $db_version \
      --gce-zone $failover_zone \
      --tier $failover_tier \
      --storage-auto-increase \
      --storage-size $storage_size \
      --master-instance-name $instance_name \
      --replica-type FAILOVER
  fi

  # set root password
  gcloud sql users set-password \
    --instance $instance_name \
    --password $root_password \
    root %

  # create a database
  gcloud sql databases create \
    --instance $instance_name \
    $database_name

  # create an application user w/ password
  gcloud sql users create \
    --instance $instance_name \
    --password $user_password \
    $database_user %
elif [ $err_code = 2 ]; then
  die "ERROR: more than one Cloud SQL instance w/ prefix: '$instance_prefix'"
else
  echo "Cloud SQL instance w/ prefix: '$instance_prefix' already created"
fi

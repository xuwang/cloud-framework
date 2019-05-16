#!/bin/bash

###############################################################################
# Destroys a cloud sql instance
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

# include functions
source $THIS_DIR/functions.sh

instance_prefix=${db_instance_prefix}

# failover instance is optional
set +u
failover_instance_prefix=${db_failover_prefix}
set -u

instance_name=$($THIS_DIR/cloud-sql-prefix-to-name.sh $instance_prefix)

if [ ! -z $failover_instance_prefix ]; then
  failover_instance_name=$($THIS_DIR/cloud-sql-prefix-to-name.sh $failover_instance_prefix)

  # delete failover replica first if exists
  echo
  echo "DELETING cloud SQL failover instance '$failover_instance_name'"
  gcloud sql instances delete $failover_instance_name
fi

echo
echo "DELETING cloud SQL master instance '$instance_name'"
gcloud sql instances delete $instance_name

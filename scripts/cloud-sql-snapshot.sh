#!/bin/bash

###############################################################################
# Snapshot a cloud sql instance
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

instance_prefix=${db_instance_prefix}
description=${db_snapshot_description}

instance_name=$($THIS_DIR/cloud-sql-prefix-to-name.sh $instance_prefix)

gcloud beta sql backups create --instance $instance_name --description "$description"

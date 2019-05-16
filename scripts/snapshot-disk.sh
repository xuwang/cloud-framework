#!/bin/bash

###############################################################################
# snapshot a disk
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

# input params
DISK_NAME=$1

snapshot_name=${DISK_NAME}-$(date +%Y%m%d-%H%M%S)

gcloud compute disks snapshot $DISK_NAME \
  --snapshot-names $snapshot_name \
  --zone $GCP_ZONE

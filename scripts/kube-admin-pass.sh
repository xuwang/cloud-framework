#!/bin/bash

###############################################################################
# get kubernetes cluster credentials from gcloud and verify
###############################################################################

THIS_DIR=$(dirname "$0")
GKE_CLUSTER_NAME=${GKE_CLUSTER_NAME:-$GCP_CLUSTER_NAME}

# include functions
source $THIS_DIR/functions.sh
source env.mk

# fail on error or undeclared vars
trap_errors

if [ -z ${GKE_CLUSTER_NAME} ]
then 
  echo "WARNING: GKE_CLUSTER_NAME is missing."
  exit 1
else
  gcloud container clusters list \
    --filter name=${GKE_CLUSTER_NAME} \
    --format "value(masterAuth.password)" | tr -d "\n\r"
fi
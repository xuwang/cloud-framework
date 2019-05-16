#!/bin/bash

###############################################################################
# DEPRECATED
# - only used in gke-cluster
# Change number of nodes in a cluster
###############################################################################

GCP_CLUSTER_NAME=${1:-$GCP_CLUSTER_NAME}
CLUSTER_RESIZE=${2:-$CLUSTER_RESIZE}

if [ -z ${CLUSTER_RESIZE} ]
then
  echo No size given, not resized.
else
  gcloud container clusters resize ${GCP_CLUSTER_NAME} --size ${CLUSTER_RESIZE}
fi

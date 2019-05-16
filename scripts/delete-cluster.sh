#!/bin/bash

###############################################################################
# delete cluster of nodes
###############################################################################

GKE_CLUSTER_NAME=${1:-$GKE_CLUSTER_NAME}
GKE_CLUSTER_ZONE=${2:-$GKE_CLUSTER_ZONE}

if gcloud container clusters describe "${GKE_CLUSTER_NAME}" > /dev/null 2>&1
then
  gcloud container clusters delete -q "${GKE_CLUSTER_NAME}" --zone "${GKE_CLUSTER_ZONE}"
else
  echo Cluster ${GKE_CLUSTER_NAME}: not found
fi

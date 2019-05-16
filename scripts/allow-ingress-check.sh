#!/bin/bash

###############################################################################
# DEPRECATED:
# Set up firewall rules if haven't been set yet
###############################################################################

GKE_CLUSTER_NAME=${1:-$GKE_CLUSTER_NAME}

# exit successfully if firewall rules are already set
if gcloud compute firewall-rules describe ${GKE_CLUSTER_NAME}-ingress-check > /dev/null 2>&1
then
  echo "Firewall ${GKE_CLUSTER_NAME}-ingress-check exist"
  exit
fi

# get a node w/ GCP_CLUSTER_NAME
NODE=$(kubectl get nodes | awk '{print $1}' | tail -n 1)
# get corresponding tag, so we can create rule with these nodes as dest
TAG=$(gcloud compute instances describe ${NODE} --format 'default(tags.items)' | grep ${GKE_CLUSTER_NAME} | awk '{print $2}')

# Set firewall rule to allow ingress check to cluster
# See https://gitlab.example.com/example/gke-cluster/issues/2
gcloud compute firewall-rules create ${GKE_CLUSTER_NAME}-ingress-check \
  --description "Allow ingress check to cluster" \
  --source-ranges "130.211.0.0/22,209.85.152.0/22,209.85.204.0/22,35.191.0.0/16" \
  --allow "tcp:30000-65535" \
  --target-tags ${TAG}

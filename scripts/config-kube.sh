#!/bin/bash

###############################################################################
# get kubernetes cluster credentials from gcloud and verify
###############################################################################

THIS_DIR=$(dirname "$0")
GKE_CLUSTER_NAME=${GKE_CLUSTER_NAME:-$GCP_CLUSTER_NAME}

KUBE_NAMESPACE=${KUBE_NAMESPACE:-default}
if [ -z ${GKE_CLUSTER_NAME} ]
then 
  echo "WARNING: GKE_CLUSTER_NAME is missing."
else
  if gcloud container clusters list --filter "name:${GKE_CLUSTER_NAME} AND status:RUNNING"| grep ${GKE_CLUSTER_NAME} &> /dev/null
  then
    location=$(gcloud container clusters list --filter "name:${GKE_CLUSTER_NAME} AND status:RUNNING" --format='value(zone)')
    # region name has 1 '-', otherwise is a zone name
    if [ "$(echo $location | grep -o '-' | wc -l)" -eq "1" ]
    then
      opt="--region=$location"
    else
      opt="--zone=$location"
    fi
    gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} $opt

    if ! kubectl version &> /dev/null; then
      kubectl version || true
      echo
      echo ERROR: cannot connect to kubernetes cluster!
      echo
    fi
    ctx=$(kubectl config current-context)
    kubectl config set-context $ctx --namespace=$KUBE_NAMESPACE
    echo Current Kubernetes Context: $ctx 
    echo Current Namespace: $KUBE_NAMESPACE
  else
    echo "WARN: GKE cluster '${GKE_CLUSTER_NAME}' is not found or status is not RUNNING"
    kubectl config set current-context UNKNOWN &> /dev/null
  fi
fi
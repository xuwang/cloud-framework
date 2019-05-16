#!/bin/bash

###############################################################################
# Create a cluster of nodes to act as hosts for kubernetes container cluster
###############################################################################

# usage $0 <cluster name> <zone> <machine type> <number of nodes> <user> <pwd>

# get command-line input, set default parameters
GKE_CLUSTER_NAME=${1:-$GKE_CLUSTER_NAME}
GKE_CLUSTER_ZONE=${2:-$GKE_CLUSTER_ZONE}
GKE_CLUSTER_MACHINE_TYPE=${3:-$GKE_CLUSTER_MACHINE_TYPE}
GKE_CLUSTER_NUM_NODES=${4:-$GKE_CLUSTER_NUM_NODES}
GKE_CLUSTER_ADDITIONAL_ZONES=${5:-$GKE_CLUSTER_ADDITIONAL_ZONES}
GKE_AUTOSCALING=${GKE_AUTOSCALING:-false}
GKE_MAX_NODES=${GKE_MAX_NODES:-5}
GKE_MIN_NODES=${GKE_MIN_NODES:-3}
GKE_DISK_SIZE=${GKE_DISK_SIZE:-100}     # number of GB

GKE_CLUSTER_USER=${GKE_CLUSTER_USER:-admin}
DEFAULT_CLUSTER_PWD=$(openssl rand -base64 24)
GKE_CLUSTER_PWD=${GKE_CLUSTER_PWD:-$DEFAULT_CLUSTER_PWD}
# GKE_TAGS is used for the NAT route sources
GKE_TAGS=${GKE_TAGS:-nat-example,goog-gke-node}
GKE_LABELS=${GKE_LABELS:-org=example}

# exit successfully if container cluster already exists
if gcloud container clusters describe "${GKE_CLUSTER_NAME}" > /dev/null 2>&1; then
  echo "Cluster ${GKE_CLUSTER_NAME} exist"
  exit
fi

# See gcloud beta container cluster create --help for availabe oauth scopes
DEFAULT_GKE_SCOPES=compute-rw,cloud-platform,storage-rw,service-control,service-management,monitoring,logging-write
GKE_SCOPES=${GKE_SCOPES:-$DEFAULT_GKE_SCOPES}

# Prefer to use long form in future
# read -r -d '' GKE_SCOPES <<EOF
# https://www.googleapis.com/auth/compute,
# https://www.googleapis.com/auth/devstorage.read_only,
# https://www.googleapis.com/auth/logging.write,
# https://www.googleapis.com/auth/monitoring,
# https://www.googleapis.com/auth/cloud-platform,
# https://www.googleapis.com/auth/servicecontrol,
# https://www.googleapis.com/auth/service.management
# EOF

if ! [ -z "${GKE_CLUSTER_ADDITIONAL_ZONES}" ]; then
  GKE_CLUSTER_ADDITIONAL_ZONES_PARAM="--additional-zones ${GKE_CLUSTER_ADDITIONAL_ZONES}"
fi

if [ "${GKE_AUTOSCALING}" = "true" ] ; then
  GKE_CLUSTER_AUTOSCALING_PARAM="--enable-autoscaling --max-nodes=${GKE_MAX_NODES} --min-nodes=${GKE_MIN_NODES}"
  GKE_CLUSTER_NUM_NODES=${GKE_MIN_NODES}
fi

if [ "${GKE_AUTOUPGRADE}" = "true" ] ; then
  GKE_AUTOUPGRADE_PARAM="--enable-autoupgrade"
fi

# must in UTC
if ! [ -z "${GKE_MAINTENANCE_WINDOW}" ] ; then 
  GKE_MAINTENANCE_WINDOW_PARAM="--maintenance-window=${GKE_MAINTENANCE_WINDOW}"
fi

if [ "${GKE_IP_ALIAS}" = "true" ] ; then
  GKE_IP_ALIAS_PARAM="--enable-ip-alias --create-subnetwork name=${GKE_CLUSTER_NAME}-subnet"
fi

if [ "${GKE_ENABLE_NET_POLICY}" = "true" ] ; then
  GKE_ENABLE_NET_POLICY_PARAM="--enable-network-policy"
fi

if ! [ -z "$GKE_AUTHZ_NET"] ; then
  GKE_AUTHZ_NET_PARAM="--enable-master-authorized-networks --master-authorized-networks ${GKE_AUTHZ_NET}"
fi

if ! [ -z "${GKE_VERSION}" ] ; then 
  GKE_VERSION_PARAM="--cluster-version=${GKE_VERSION}"
fi

# create cluster
gcloud beta container clusters create "${GKE_CLUSTER_NAME}" \
    ${GKE_CLUSTER_ADDITIONAL_ZONES_PARAM} \
    ${GKE_IP_ALIAS_PARAM} \
    ${GKE_CLUSTER_AUTOSCALING_PARAM} \
    ${GKE_AUTOUPGRADE_PARAM} \
    ${GKE_MAINTENANCE_WINDOW_PARAM} \
    ${GKE_ENABLE_NET_POLICY_PARAM} \
    ${GKE_AUTHZ_NET_PARAM} \
    ${GKE_VERSION_PARAM} \
    --zone="${GKE_CLUSTER_ZONE}" \
    --machine-type="${GKE_CLUSTER_MACHINE_TYPE}" \
    --num-nodes=${GKE_CLUSTER_NUM_NODES} \
    --username="${GKE_CLUSTER_USER}" \
    --password="${GKE_CLUSTER_PWD}" \
    --enable-cloud-logging \
    --enable-cloud-monitoring \
    --scopes="${GKE_SCOPES}" \
    --disk-size="${GKE_DISK_SIZE}" \
    --no-async \
    --enable-autorepair \
    --tags="${GKE_TAGS}" \
    --labels="${GKE_LABELS}"
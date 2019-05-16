#!/bin/bash

###############################################################################
# Create a persistent disk
###############################################################################

# Usage: $0 <disk name> <size> <type> <zone> <snapshort>

function is_region() {
    #https://unix.stackexchange.com/questions/32250/why-does-a-0-let-a-return-exit-code-1/32251#32251
    number_of_dash=$(echo $1 | awk -F"-" '{print NF-1}')
    ! (( ${number_of_dash} - 1 )) 
}

# get command-line input, set default parameters
DISK_NAME=${1:-$DISK_NAME}
DISK_SIZE=${2:-$DISK_SIZE}
DISK_TYPE=${3:-pd-standard}
DISK_LOCATION=${4:-$GCP_ZONE}
SNAPSHOT=$5

if gcloud compute disks list | grep ${DISK_NAME} &> /dev/null
then
    gcloud beta compute disks delete ${DISK_NAME} ${location_opt} --quiet
else
    echo ${DISK_NAME} not exists, do nothing
fi

# Set default disk replica-zones, i.e. a and c
if [ -z "$DISK_REPLICA_ZONES" ]
then
    DISK_REPLICA_ZONES="${DISK_LOCATION}-a,${DISK_LOCATION}-c"
fi

if is_region ${DISK_LOCATION}
then
    location_opt="--region ${DISK_LOCATION} --replica-zones ${DISK_REPLICA_ZONES}"
else
    location_opt="--zone ${DISK_LOCATION}"
fi

# create disk
if [ -z ${SNAPSHOT} ]
then

  gcloud beta compute disks create ${DISK_NAME} \
    ${location_opt} \
    --size ${DISK_SIZE} \
    --type ${DISK_TYPE} 
else
  gcloud beta compute disks create ${DISK_NAME} \
    ${location_opt} 
    #{replica_opt} \
    --size ${DISK_SIZE} \
    --type ${DISK_TYPE} \
    --source-snapshot ${SNAPSHOT} 
fi
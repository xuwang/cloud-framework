#!/bin/bash

###############################################################################
# delete persistent disk
###############################################################################

DISK_NAME=${1:-$DISK_NAME}
ZONE=${2:-$GCP_ZONE}

gcloud compute disks delete ${DISK_NAME} --zone ${ZONE}


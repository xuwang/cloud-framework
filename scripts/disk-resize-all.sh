#!/bin/bash -e
#
# Resize persistent disk defined in def_file
# Only increasing disk size is supported. 
# Disks can be resized regardless of whether they are attached.
# Usage:
#     $0  def_file
#
# The format of def_file is one line for per persistent disk:
#   <disk_name> <disk_size> [<disk_type>] [<disk_zone>] [<snapshort>]

function resize_disk() {
    # Usage: $0 <disk name> <zone> <size> <type>

    # get command-line input, set default parameters
    DISK_NAME=${1:-$DISK_NAME}
    DISK_SIZE=${2:-$DISK_SIZE}

    if [ -z "$DISK_SIZE" ]
    then
        echo "DISK_SIZE is missing for ${DISK_NAME}!"
        return
    fi

    if gcloud compute disks list | grep ${DISK_NAME} &> /dev/null
    then
        # Only increasing disk size is supported. 
        OLD_SIZE=$(gcloud compute disks describe ${DISK_NAME} --format='value(sizeGb)')
        NEW_SIZE=${DISK_SIZE%%GB}
        echo "${DISK_NAME} NEW_SIZE=${NEW_SIZE}GB OLD_SIZE=${OLD_SIZE}GB"
        if [[ $NEW_SIZE -gt $OLD_SIZE ]]
        then
            gcloud compute disks resize "${DISK_NAME}" --size ${DISK_SIZE}
            users=$(gcloud compute disks describe ${DISK_NAME} --format='value(users)')
            echo "${DISK_NAME} is resized to ${DISK_SIZE}"
            echo "Please sudo resize2fs to resize the file system, and you may also need to patch k8s pv/pvc."
            if [ ! -z "$users" ]
            then
                echo ${DISK_NAME} users: $users
            fi
        fi 
    else
        echo "${DISK_NAME} not exists, do nothing"
    fi
}

grep -v '^#' $1 | grep -v -e '^$' | render.sh |
while read -r line; do
    resize_disk $line
done

#!/bin/bash -e
#
# Create persistent disk defined in def_file
# Usage:
#     $0  def_file
# The format of def_file is one line for per persistent disk:
#   <disk_name> <disk_size> [<disk_type>] [<disk_location>]

function is_region() {
    #https://unix.stackexchange.com/questions/32250/why-does-a-0-let-a-return-exit-code-1/32251#32251
    number_of_dash=$(echo $1 | awk -F"-" '{print NF-1}')
    ! (( ${number_of_dash} - 1 )) 
}

function describe_disk() {
    # Usage: $0 <disk name> <size> <type> <location>

    # get command-line input, set default parameters
    DISK_NAME=${1:-$DISK_NAME}
    DISK_LOCATION=${4:-$GCP_ZONE}

    if is_region ${DISK_LOCATION}
    then
        location_opt="--region ${DISK_LOCATION}"
    else
        location_opt="--zone ${DISK_LOCATION}"
    fi

    if gcloud compute disks list | grep ${DISK_NAME} &> /dev/null
    then
        gcloud beta compute disks describe ${DISK_NAME} ${location_opt} 
    else
        echo ${DISK_NAME} not exists
    fi
}

grep -v '^#' $1 | grep -v -e '^$' | render.sh |
while read -r line; do
    describe_disk $line
done
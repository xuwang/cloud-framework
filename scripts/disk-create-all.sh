#!/bin/bash -e
#
# Create persistent disk defined in def_file
# Usage:
#     $0  def_file
#
# The format of def_file is one line for per persistent disk:
#   <disk_name> <disk_size> [<disk_type>] [<disk_location>] [<snapshort>]

function is_region() {
    #https://unix.stackexchange.com/questions/32250/why-does-a-0-let-a-return-exit-code-1/32251#32251
    number_of_dash=$(echo $1 | awk -F"-" '{print NF-1}')
    ! (( ${number_of_dash} - 1 )) 
}

function create_disk() {
    # Usage: $0 <disk name> <size> <type> <location> <snapshot>

    # get command-line input, set default parameters
    DISK_NAME=${1:-$DISK_NAME}
    DISK_SIZE=${2:-$DISK_SIZE}
    DISK_TYPE=${3:-pd-standard}
    DISK_LOCATION=${4:-$GCP_ZONE}
    DISK_SNAPSHOT=$5


    if [ -z "$DISK_SIZE" ]
    then
        echo ERROR DISK_SIZE is missing for ${DISK_NAME}!
        exit 1
    fi

    if [ -z "$DISK_LOCATION" ]
    then
        echo ERROR GCP_ZONE is missing for ${DISK_NAME}!
        exit 1
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


    # exit if disk already created
    if gcloud compute disks list | grep ${DISK_NAME} &> /dev/null
    then
        echo ${DISK_NAME} exists, do nothing
    else
        # create disk
        if [ -z ${DISK_SNAPSHOT} ]
        then
            gcloud beta compute disks create "${DISK_NAME}" \
                ${location_opt} \
                --size ${DISK_SIZE} \
                --type ${DISK_TYPE}
        else
            echo Creating disk "${DISK_NAME}" ${DISK_LOCATION} from snapshot "${DISK_SNAPSHOT}"...
            gcloud beta compute disks create "${DISK_NAME}" \
                ${location_opt} \
                --size ${DISK_SIZE} \
                --type ${DISK_TYPE} \
                --source-snapshot "${DISK_SNAPSHOT}"
        fi
    fi
}

grep -v '^#' $1 | grep -v -e '^$' | render.sh |
while read -r line; do
    create_disk $line
done

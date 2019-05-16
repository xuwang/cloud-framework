#!/bin/bash -e
#
# Getting registroy password value from vault and adding the docker registry to drone
# Usage:
#     $0 registry_def_file
#
# The format of registry_def_file is one line for each docker registry:
#   <registry_host> <registry_username> <regitry_passward>
#
# NOTE: vault must already logged in!

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}


function get_value(){
    local value=$1
    if [[ $value == file://* ]]; then 
        echo -n "@${value#value://}"
    elif [[ $value == base64file://* ]]; then
        cat ${value#base64file://} | base64 | tr -d '\n'
    elif [[ $value == vault://* ]]; then
        vault-read.sh ${value#vault://}
    elif [[ $value == base64vault://* ]]; then
        vault-read.sh ${value#base64vault://} | base64 | tr -d '\n'
    else
        echo -n $value
    fi
}

function add_registry() {
    pass=$(get_value $3)

    # add the registry before add
    if drone registry ls  --repository "${DRONE_REPO}" | grep "$1" > /dev/null ; then
        drone registry rm  --repository "${DRONE_REPO}" --hostname "$1"
    fi

    drone registry add  --repository "${DRONE_REPO}" --hostname "$1" --username "$2" --password "$pass"
}

if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi
if [ -z "${DRONE_TOKEN}" ]; then
    echo ERROR: DRONE_TOKEN are not defined
    exit 1
fi

if [ -z "${DRONE_REPO}" ]; then
    echo ERROR: DRONE_REPO is not defined
    exit 1
fi

grep -v '^#' $1 | grep -v -e '^$' | render.sh |
while read -r line; do
    add_registry $line
done

#!/bin/bash -e
#
# remvoe a drone registry
# Usage:
#     $0 registry_def_file
#
# The format of registry_def_file is one line for each docker registry:
#   <registry_host> <registry_username> <regitry_passward>
#

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}

if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi

if [ -z "${DRONE_REPO}" ]; then
    echo ERROR: DRONE_REPO is not defined
    exit 1
fi

if [ -z "${DRONE_TOKEN}" ]; then
    if [ -z "${DRONE_TOKEN_PATH}" ]; then
        echo ERROR: DRONE_TOKEN and DRONE_TOKEN_PATH are not defined
        exit 1
    fi
    export DRONE_TOKEN=$(vault-read.sh ${DRONE_TOKEN_PATH})
fi


function rm_registry() {
    # remove the registry
    if drone registry info  --repository ${DRONE_REPO} --name $1 > /dev/null ; then
        drone registry rm  --repository ${DRONE_REPO} --name $1
    fi
}

grep -v '^#' $1 | grep -v -e '^$' |
while read -r line; do
    rm_registroy $line
done

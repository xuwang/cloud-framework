#!/bin/bash -e
#
# remvoe a drone sec
# Usage:
#     $0 <key>
#
# NOTE: vault must already logged in!

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

key=$1

# remove the sec
if drone secret info  --repository ${DRONE_REPO} --name $key > /dev/null ; then
    drone secret rm  --repository ${DRONE_REPO} --name $key
fi

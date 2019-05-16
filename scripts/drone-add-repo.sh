#!/bin/bash

###############################################################################
# DEPRECATED: only used in drone.mk, which used by:
# - docker-vault-init
# - kube-vault-ui
# - provision-keycloak
# - provision-vault
# add a repo to drone
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=$PATH:$THIS_DIR

# include functions
source $THIS_DIR/functions.sh

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}

if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi
if [ -z "${DRONE_TOKEN}" ]; then
    echo ERROR: DRONE_TOKEN are not defined
    exit 1
fi


# fail on error or undeclared vars
trap_errors

if ! drone-cli.sh repo info ${DRONE_REPO} > /dev/null 2>&1; then
  drone-cli.sh repo add ${DRONE_REPO}
fi

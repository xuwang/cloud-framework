#!/bin/bash

###############################################################################
# wrapper for docker drone CLI
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=$PATH:$THIS_DIR

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

if [ -f ${DRONE_TOKEN_FILE} ]; then
  DRONE_TOKEN=$(cat ${DRONE_TOKEN_FILE});
else
  >&2 echo "${DRONE_TOKEN_FILE} doesn't exist"
  false
fi

docker run --rm -i \
  -v ${PWD}/${SEC_PATH}:/secrets \
  -v ${DRONE_CLI_WORKDIR}:/workdir \
  -e DRONE_TOKEN=${DRONE_TOKEN} \
  -e DRONE_SERVER=${DRONE_SERVER} \
  -w /workdir ${DRONE_CLI_IMAGE} \
  "${@/$SEC_PATH//secrets}"

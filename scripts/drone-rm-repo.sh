#!/bin/bash

###############################################################################
# remove a repo from drone
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=$PATH:$THIS_DIR

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}

if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi

if ${DRONE_CLI} repo info ${DRONE_REPO} &> /dev/null; then
	read -p "Remove repo from drone will DESTROY BUILD HISTORY, are you sure? [Y/n] " ; \
  if [ "$REPLY" = 'Y' ]; then
		echo "drone repo rm ${DRONE_REPO}"
		drone-cli.sh repo rm ${DRONE_REPO}
	else
		echo "canceled remove repo action"
	fi
fi

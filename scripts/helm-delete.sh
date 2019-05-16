#!/bin/bash

###############################################################################
# Do a helm delete with a values file processed by gomplate
###############################################################################

THIS_DIR=$(dirname "$0")
PATH="${THIS_DIR}:${PATH}"

# include functions
source $THIS_DIR/functions.sh

usage() {
    echo "USAGE:"
    echo 'install the latest version of a chart from ${FRAMEWORK_DIR}/helm-charts'
    echo "   helm_chart_name=external_dns ./helm-install.sh"
    echo 
    echo 'install a specific version of a chart from ${FRAMEWORK_DIR}/helm-charts'
    echo "   helm_chart_name=external_dns helm_chart_version=0.1.0 ./helm-install.sh"
    echo 
}

# GLOBALS
CHARTS_PATH=${FRAMEWORK_DIR}/helm-charts

trap_errors

# input environment variables
# variables are lowercase to make a point that these aren't global variables
# - variables can be reset multiple times to allow for multiple installs
set +u
helm_release_name=${helm_release_name:-$HELM_RELEASE_NAME}

# debug input environment variables
# optional
if [ "$debug_helm" = "true" ]; then
	extra_cmd_args=--dry-run
	extra_global_args=--debug
else
	extra_cmd_args=
	extra_global_args=
fi
set -u

if  [ -z "$HELM" ]; then
    HELM=helm
fi

if helm list | grep ${helm_release_name} &> /dev/null
then 
    ${HELM} ${extra_global_args} \
        delete --purge ${helm_release_name} \
        ${extra_cmd_args}
fi
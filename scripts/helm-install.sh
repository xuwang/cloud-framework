#!/bin/bash

###############################################################################
# Do a helm install with a values file processed by gomplate
###############################################################################

THIS_DIR=$(dirname "$0")
PATH="${THIS_DIR}:${PATH}"

# include functions
source $THIS_DIR/functions.sh

trap_errors

usage() {
    echo "${0} USAGE:"
    echo 
    echo 'install "local" chart ${COMMON}/charts/my-chart'
    echo '   # if there is chart at ${COMMON}/charts/my-chart (local chart has precedence)'
    echo '   export HELM_CHART=my-chart'
    echo "   helm-install.sh"
    echo 
    echo 'install latest version of "global" chart ${FRAMEWORK_DIR}/helm-charts/my-chart/latest'
    echo '   # if ${COMMON}/charts/my-chart DOES NOT exist'
    echo '   export HELM_CHART=my-chart'
    echo '   helm-install.sh'
    echo 
    echo 'install specific version of "global" chart ${FRAMEWORK_DIR}/helm-charts/my-chart/0.1.0'
    echo '   # if ${COMMON}/charts/my-chart DOES NOT exist'
    echo "   export HELM_CHART=my-chart"
    echo "   export HELM_CHART_VERSION=0.1.0"
    echo "   helm-install.sh"
    echo
    echo 'install multiple "local" or "global" (latest version) charts'
    echo '   # will check ${COMMON}/charts first, then ${FRAMEWORK_DIR}/helm-charts'
    echo "   helm_chart=my-chart ./helm-install.sh"
    echo "   helm_chart=my-other-chart ./helm-install.sh"
    echo
    echo 'debug the values passed to your chart via $helm_values_template'
    echo "   debug_gomplate=true helm_chart=my-chart ./helm-install.sh"
    echo
    echo 'do a helm --dry-run'
    echo "   debug_helm=true helm_chart=external-dns ./helm-install.sh"
    echo

    exit 1
}

set +u
if [ "$1" = "-h" ]; then
    usage
fi
set -u

# GLOBALS
GLOBAL_CHARTS_DIR=${FRAMEWORK_DIR}/helm-charts
LOCAL_CHARTS_DIR=${COMMON}/helm-charts
GOMPLATE_TEMPLATE_NAME=chart-input-values.gomplate.yaml

# VARIABLES
# by using lowercase variables for inputs, we are making it clear that inputs aren't globals
# instead, the script can be used multiple times within a project, allowing installation of several charts

set +u

# lowercase variables intended to be passed as "argument", UPPERCASE are to be read from "global" env variable
# "arguments" (lowercase) have precedence over "globals" (uppercase)
helm_release_name=${helm_release_name:-$HELM_RELEASE_NAME}
if [ -z $helm_release_name ]; then
    >&2 echo "ERROR: helm_release_name or HELM_RELEASE_NAME must be set!"
fi

helm_chart=${helm_chart:-$HELM_CHART}

helm_namespace=${helm_namespace:-$HELM_NAMESPACE}
if [ -z $helm_namespace ]; then
    helm_namespace=default
fi

helm_chart_version=${helm_chart_version:-$HELM_CHART_VERSION}
if [ -z $helm_chart_version ]; then
    helm_chart_version=latest
fi

debug_gomplate=${debug_gomplate}
debug_helm_template=${debug_helm_template}

if [ "$debug_helm" = "true" ]; then
	extra_cmd_args=--dry-run
	extra_global_args=--debug
else
	extra_cmd_args=
	extra_global_args=
fi
set -u

# no versioning needed for local chart
local_chart_path=${LOCAL_CHARTS_DIR}/${helm_chart}
global_chart_path=${GLOBAL_CHARTS_DIR}/${helm_chart}/${helm_chart_version}

# prefer local_chart_path if it exists
if [ -d $local_chart_path ]; then
    helm_chart_path=$local_chart_path
else
    if [ -d $global_chart_path ]; then
        helm_chart_path=$global_chart_path

        if [ "$helm_chart_version" = "latest" ]; then
            >&2 echo "WARNING: using 'latest' version of global chart which is subject to change"
        fi
    else
        >&2 echo "ERROR: no chart at ${global_chart_path} or ${local_chart_path}" && false
    fi
fi

# gomplate helm values template can go in chart
helm_values_template=${helm_chart_path}/${GOMPLATE_TEMPLATE_NAME}

if ! [ -f $helm_values_template ]; then
    >&2 echo "ERROR: file helm_values_template='${helm_values_template}' does not exist" && false
fi

if [ "$debug_gomplate" = "true" ]; then
    echo 
    echo "Rendered ${GOMPLATE_TEMPLATE_NAME}:"
    echo
    cat $helm_values_template | gomplate.sh
    echo
    echo
    exit 1
fi

if  [ -z "$HELM" ]; then
    HELM=helm
fi

if [ "$debug_helm_template" = "true" ]; then
    cat $helm_values_template | gomplate.sh | 
        $HELM \
            template -f - \
            --name ${helm_release_name} \
            ${helm_chart_path} \
            --namespace "${helm_namespace}"
    exit 1
fi

echo "installing chart $helm_chart_path"
cat $helm_values_template | gomplate.sh | \
    $HELM ${extra_global_args} \
        install -f - \
        ${extra_cmd_args} \
        --name ${helm_release_name} \
        ${helm_chart_path} \
        --namespace "${helm_namespace}"
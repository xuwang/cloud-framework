#!/bin/bash -e
#
# Getting sec value from vault and adding drone sec
# Usage:
#     $0 <key> <value> [command options]
#     value format
#           vault://<path>
#           base64vault://<path>
#           file://<path>
#           base64file://<path>
#           @filename
#           string_value
#
# NOTE: vault must already logged in!

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}

function get_value(){
    local value=$1
    if [[ $value == file://* ]]; then 
        echo -n "@${value#file://}"
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


if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi

if [ -z "${DRONE_REPO}" ]; then
    echo ERROR: DRONE_REPO is not defined
    exit 1
fi

if [ -z "${DRONE_TOKEN}" ]; then
    echo ERROR: DRONE_TOKEN are not defined
    exit 1
fi

key=$1

# remove the sec before add
if drone secret ls  --repository ${DRONE_REPO}  | grep "$key" &> /dev/null ; then
    drone secret rm  --repository ${DRONE_REPO} --name "$key"
fi

sec_path=$2
value=$(get_value $sec_path)
shift
shift

options=$*

if [[ -z "$value" ]]; then
    echo ERROR missing value for $key
    exit 1
fi
drone secret add --repository ${DRONE_REPO} --name "$key" -value "$value" $options
echo Add $key=$sec_path to drone secrets

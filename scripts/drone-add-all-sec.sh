#!/bin/bash
#
# Add all drone secrets defined in a file, $1
# The file format is
#   <sec_name> <sec_value> <sec_options> ....

#   <sec_value> format
#           vault://<path>
#           file://<path>
#           string_value
#

export DRONE_CLI_VERSION=${DRONE_CLI_VERSION:-0.8.0}

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

function get_key() {
    echo $1
}
function get_sec() {
    echo $2
}
function get_options() {
    shift
    shift
    echo $*
}

function add_all() {
    grep -v '^#' $1 | grep -v -e '^$' | render.sh |
    while read -r line; do
        key=$(get_key $line)
        sec=$(get_sec $line)
        [[ -z "$key" ]] || [[ -z "$sec" ]] && continue
        $THIS_DIR/drone-add-sec.sh $key $sec $(get_options $line)
    done
}


if ! drone --version | grep ${DRONE_CLI_VERSION} > /dev/null ; then
    echo ERROR: drone ${DRONE_CLI_VERSION} is required!
    exit 1
fi
if [ -z "${DRONE_TOKEN}" ]; then
    echo ERROR: DRONE_TOKEN are not defined
    exit 1
fi

try add_all $*
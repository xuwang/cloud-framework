#!/bin/bash
#
# Remove all drone secrets defined in a file, $1
#

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

function key() {
    echo $1
}

function rm_all() {
    grep -v '^#' $1 | grep -v -e '^$' |
    while read -r line; do
        # get key
        key=$(key $line)
        [[ -z "$key" ]]  && continue
        $THIS_DIR/drone-rm-sec.sh $key
    done
}

try rm_all $*
#!/bin/bash

###############################################################################
# convert a flat yaml file to --args string
###############################################################################

THIS_DIR=$(dirname "$0")
PATH=${THIS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

yaml_file=$1
ignore_keys=${@:2}

json=$(gomplate < $yaml_file | yaml2json.sh)
keys=$(echo "$json" | yaml2json.sh | jq -er '. | keys[]')
arg_string=
for key in $keys; do
    if [[ $ignore_keys == *"$key"* ]]; then
        continue
    fi
    value=$(echo "$json" | jq -er ".[\"$key\"]")
    arg_string="$arg_string --${key}='${value}'"
done
printf "$arg_string"
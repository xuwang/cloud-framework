#!/bin/bash

###############################################################################
# Returns a single sql instance for given prefix
# if there are no results, or more than one result the script fails
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

prefix=$1

results=$(gcloud --format json sql instances list --filter "name : $prefix*")

# return false (thus exiting) if there isn't a single match
if echo $results | jq -e '. | length == 0' > /dev/null; then
  >&2 echo "ERROR: no cloud sql instance matching prefix '$prefix'"
  exit 1
elif echo $results | jq -e '. | length > 1' > /dev/null; then
  >&2 echo "ERROR: more than one cloud sql instance matching prefix '$prefix'"
  exit 2
else
  echo $results | jq -re .[0].name
fi

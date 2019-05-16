#!/bin/bash

###############################################################################
# replace resource definitions using list of input templates
###############################################################################

THIS_DIR=$(dirname "$0")
PATH="${THIS_DIR}:${PATH}"

# include functions
source $THIS_DIR/functions.sh
source env.mk

# fail on error or undeclared vars
trap_errors

# optional vars
set +u
debug=$debug
set -u

template_files=$@

for template in $template_files; do
  echo "   $template"
  if [ "$debug" = "true" ]; then
    cat $template | render.sh 
  else
    echo replacing kubernetes resources with $template
    cat $template | render.sh | kubectl replace --force -f -
  fi
done

#!/bin/bash

###################################################################################
# a filter that renders a template, usage: cat <file> | render.sh
# Note: if gomlate ds vault is used, VAULT_ADDR must be defined and auth done.
####################################################################################

THIS_DIR=$(dirname "$0")
FRAMEWORK_DIR=${FRAMEWORK_DIR:-..}

# include functions
#source $THIS_DIR/functions.sh
#templates_dir=$FRAMEWORK_DIR/gomplate-includes


IFS= read -r first_line

case "$first_line" in
        *\#!gomplate*   ) 
            # render gomplate tmpt
            cat - | gomplate -d vault="vault://" "$@"
            ;;
        *\#!vault2kube*  )  
            # render vault2kube tmpt
            cat - | envsubst | vault2kube.sh
            ;;
        *\#!envsubst*   ) 
            # render envsubst tmpt
            cat - | envsubst
            ;;
        *               )
            # do nothing
            # echo $first_line 
            # cat -     

            # default render envsubst tmpt, don't strip the first_line
            (echo $first_line; cat - ) | envsubst
            ;;
esac

#!/bin/bash

###############################################################################
# Uses secrets-rotate.yaml file to 
############################################################################### 
THIS_DIR=$(dirname "$0")
SECRETS_ROTATE_SCRIPTS_DIR=$THIS_DIR/secrets-rotate-scripts
PATH=${SECRETS_ROTATE_SCRIPTS_DIR}:${PATH}

# include functions
source $THIS_DIR/functions.sh

trap_errors

secrets_rotate_file=$1
mode=$2

if [ "$mode" = "rotate" ] || [ "$mode" = "cleanup" ]; then
    if [ "$mode" = "rotate" ]; then
        read -p "Are you sure you want to rotate secrets, potentially rotating active credentials? (y/N)? " -n 1 -r
    else
        read -p "Are you sure you want to cleanup secrets, potentially deleting active credentials? (y/N)? " -n 1 -r
    fi

    echo
    if ! [[ $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

# LOOP OVER secrets rotate YAML file
 ${THIS_DIR}/gomplate.sh < $secrets_rotate_file | yaml2json.sh | jq -ec .secrets[] | while read -r secret; do
    # CLEANUP SCRIPT
    # cleanup script (optional) is to clean up extra credentials after the application is changed to use new credentials
    if [ "$mode" = "cleanup" ]; then
        if cleanup_script=$(echo $secret | jq -er .cleanupScript.script); then
            # set up environment variables for cleanup script
            if echo $secret | jq -e .cleanupScript.environment[] > /dev/null 2>&1; then
                for env_var in $(echo $secret | jq -ec .cleanupScript.environment[]); do
                    name=$(echo $env_var | jq -er .name)
                    value=$(echo $env_var | jq -er .value)
                    declare $name=$value
                    export $name
                done
            fi
            $cleanup_script
            # clean up environment variables for cleanup script
            if echo $secret | jq -e .cleanupScript.environment[] > /dev/null 2>&1; then
                for env_var in $(echo $secret | jq -ec .cleanupScript.environment[]); do
                    name=$(echo $env_var | jq -er .name)
                    unset $name
                done
            fi
        fi
        continue
    fi

    # CREATE/ROTATE SCRIPT
    vault_path=$(echo $secret | jq -er .vaultPath)
    export vault_path
    if ! rotate_script=$(echo $secret | jq -er .rotateScript.script); then
        rotate_script=vault-kv.sh
    fi
    # set up environment variables for rotate script if present
    if echo $secret | jq -e .rotateScript.environment[] > /dev/null 2>&1; then
        for env_var in $(echo $secret | jq -ec .rotateScript.environment[]); do
            name=$(echo $env_var | jq -er .name)
            value=$(echo $env_var | jq -er .value)
            declare $name=$value
            export $name
        done
    fi
    if [ "$mode" = "rotate" ]; then
        echo "ROTATING SECRET at vault path '$vault_path' w/ rotate script $rotate_script"
    elif [ "$mode" = "generate" ]; then
        echo "GENERATING SECRET at vault path '$vault_path' w/ rotate script $rotate_script"
    fi

    if message=$(echo $secret | jq -er .message); then
        echo "- $message"
    fi
    $rotate_script $mode
    # clean up environment variables for rotate script if exist
    if echo $secret | jq -e .rotateScript.environment[] > /dev/null 2>&1; then
        for env_var in $(echo $secret | jq -ec .rotateScript.environment[]); do
            name=$(echo $env_var | jq -er .name)
            unset $name
        done
    fi
done

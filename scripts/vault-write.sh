#!/bin/bash
# Usage:
#   vault-write <path> [<secret vaule> | @<secret file>]

THIS_DIR=$(dirname "$0")

export GCP_ENVIRONMENT=${GCP_ENVIRONMENT:-dev}
export SEC_ENV=${SEC_ENV:-$GCP_ENVIRONMENT}
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

if ! vault --version | grep 'v1.' &> /dev/null
then
    (>&2 echo "The vault version is too old, please upgrade the vault cmd.")
    exit 1
fi

path=$(echo $1 | render.sh)

if [[ "$2" =~ ^@ ]];
then
    # if the data is in a file
    src=$(echo $2 | cut -c 2-)
    if file -b --mime-encoding $src | grep -s binary > /dev/null
    then
        # if data is binary, base64 encode it and set format=base64
        value=$(cat $src | base64)
        format=base64
    else
        # otherwise set format=text
        value=$(cat $src)
        format=text
    fi
else
    value=$2
    format=text
fi
vault kv put $path value="$value" format="$format"

#!/bin/bash
# Usage:
#   vault-read <path>

THIS_DIR=$(dirname "$0")

export GCP_ENVIRONMENT=${GCP_ENVIRONMENT:-dev}
export SEC_ENV=${SEC_ENV:-$GCP_ENVIRONMENT}
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

if ! vault --version | grep 'v1.' &> /dev/null
then
    (>&2 echo "The vault version is too old, please upgrade the vault cmd.")
    exit 1
fi

path=$(echo $1 | ${THIS_DIR}/render.sh)

# Get the kv sec from path in json
j=$(vault kv get -format=json $path)
f=$(echo $j | jq -r '.data.format//.data.data.format' 2> /dev/null)
v=$(echo $j | jq -r '.data.value//.data.data.value')

# if value format is base64, decode it
if [ "base64" == "$f" ]
then
    echo -n "$v" | base64 --decode
else
    echo -n "$v"
fi

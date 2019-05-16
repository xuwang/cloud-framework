#!/bin/bash
# Get the secret wrapped by a vault token
# Usage:
#   vault-unwrap.sh <wrap_token> <options>

if ! which vault > /dev/null
then 
    echo vault cli is missing, please install it from https://www.vaultproject.io/downloads.html
    exit 1
fi
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}
export VAULT_TOKEN=$1

shift
vault unwrap $@

# api version
# curl -sSL --header "X-Vault-Token: $VAULT_TOKEN" --request POST $VAULT_ADDR/v1/sys/wrapping/unwrap
#!/bin/bash

###############################################################################
# login to vault
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

trap_errors

set +u # optional vars
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}
export SEC_PATH=${SEC_PATH:-auth/token/lookup-self}
export VAULT_AUTH_PATH=${VAULT_AUTH_PATH:-ldap}
export VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-ldap}
export VAULT_USER=${VAULT_USER:-$USER}
export VAULT_ROLE_ID=${VAULT_ROLE_ID}
set -u

echo "VAULT SERVER: $VAULT_ADDR"

if ! [ -z $VAULT_ROLE_ID ]; then
    echo "attempting to login in w/ approle provided in env vars VAULT_ROLE_ID & VAULT_SECRET_ID"
    vault write -format json auth/approle/login \
        role_id=$VAULT_ROLE_ID \
        secret_id=$VAULT_SECRET_ID \
        | jq -er .auth.client_token > ~/.vault-token
fi

if ! vault token lookup > /dev/null 2>&1; then
    if ! [ -z $VAULT_ROLE_ID ]; then
        >&2 "ERROR: VAULT_TOKEN does not exist or is not valid" && false
    fi

    echo "Please login VAULT as vault user ${VAULT_USER} with DUO device ready:"
    vault login -method=${VAULT_AUTH_METHOD} -path=${VAULT_AUTH_PATH} username=${VAULT_USER}
fi

if vault token capabilities ${SEC_PATH}/* | grep  -E -q "read|root"; then
    echo "You are logged in VAULT and have permission to read from ${SEC_PATH}/*"
else
    if ! [ -z $VAULT_ROLE_ID ]; then
        >&2 "ERROR: no permission to read from ${SEC_PATH}/*" && false
    fi

    echo "Permission denied to read from ${SEC_PATH}/*, please login again as vault user ${VAULT_USER}:"
    vault login -method=${VAULT_AUTH_METHOD} -path=${VAULT_AUTH_PATH} username=${VAULT_USER}
fi

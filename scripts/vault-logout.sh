#!/bin/bash
# Revoke login token and all its children
# and cleanup local cache

THIS_DIR=$(dirname "$0")

export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}
VAULT_CACHE=${VAULT_CACHE:-$HOME/.vault-local}

echo "Logout ${VAULT_ADDR}"
vault token revoke -self &> /dev/null
rm -f ${HOME}/.vault-token

# Cleanup local cache
rm -rf ${VAULT_CACHE}

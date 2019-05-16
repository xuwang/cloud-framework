#!/bin/bash
THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

vault_info() {
    export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}
    VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-ldap}
    SEC_PATH=${SEC_PATH:-auth/token/lookup-self}

    echo "VAULT SERVER: $VAULT_ADDR"
    # seal status (0 unsealed, 2 sealed, 1 error)
    vault status
    [[ $? -eq 1 ]] && die "Error checking vault status."
    if vault-list.sh ${SEC_PATH} 2>&1 >/dev/null | grep 'missing client token' 2>&1 >/dev/null
    then
        echo "You are not logged in VAULT"
    elif vault-list.sh ${SEC_PATH} 2>&1 >/dev/null | grep 'permission denied' 2>&1 >/dev/null
    then
        echo "You are logged in VAULT but you don't have permissions to access ${SEC_PATH}"
    else
        echo "You are logged in VAULT and has the access to ${SEC_PATH}"
        vault read auth/token/lookup-self
    fi
}

vault_info

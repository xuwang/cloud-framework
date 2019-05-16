#!/bin/bash -e
# Usage:
#   vault-read <path>

# include functions
THIS_DIR=$(dirname "$0")

export GCP_ENVIRONMENT=${GCP_ENVIRONMENT:-dev}
export SEC_ENV=${SEC_ENV:-$GCP_ENVIRONMENT}
export VAULT_ADDR=${VAULT_ADDR:-https://vault.example.com}

path=$(echo $1 | ${THIS_DIR}/render.sh)

vault kv list $path
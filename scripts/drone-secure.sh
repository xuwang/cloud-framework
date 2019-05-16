#!/bin/bash

###############################################################################
# Encrypt secrets for drone ci
###############################################################################

THIS_DIR=$(dirname "$0")
DRONE_BASE_DIR="${DRONE_BASE_DIR:-.}"

# include functions
source $THIS_DIR/functions.sh
source env.mk

# fail on error or undeclared vars
trap_errors

# Set git-crypt key if the repo is protected:
if [[ -f .git/git-crypt/keys/default ]]
then
  GIT_KEY=$(cat .git/git-crypt/keys/default | base64 | tr -d '\n')
else
  GIT_KEY=""
fi


if empty_var GCP_KEY_FILE
then
  GCP_KEY="Unknown"
else
  GCP_KEY=$(cat $GCP_KEY_FILE | base64 | tr -d '\n')
fi

# Docker registry key
# Note: this key may used by docker plugins, so it can't be base64 encoded.
# To be yaml safe, format the key into one line string.
if empty_var REGISTRY_KEY_FILE
then
  REGISTRY_KEY="Unknown"
else
  REGISTRY_KEY=$(cat $REGISTRY_KEY_FILE | grep -v '^$' | paste -s -d" " -)
fi

# Slack notifaction url
if empty_var SLACK_URL_FILE
then
  SLACK_URL="Unknown"
else
  SLACK_URL=$(cat $SLACK_URL_FILE )
fi

# Downstream drone repo token
if empty_var DRONE_TOKEN_FILE
then
  DRONE_TOKEN="Unknown"
else
  DRONE_TOKEN=$(cat $DRONE_TOKEN_FILE)
fi

export PROJECT_ID
export IMAGE
export DRONE_REPO
export GIT_KEY
export GCP_KEY
export REGISTRY_KEY
export REGISTRY_EMAIL=$(whoami)@example.com
export SLACK_URL
export DRONE_TOKEN

cat ${DRONE_BASE_DIR}/.drone.sec.yml | render.sh \
  | drone --server ${DRONE_SERVER} \
    --token ${DRONE_TOKEN} secure \
    --repo ${DRONE_REPO} \
    --out ${DRONE_BASE_DIR}/.drone.sec \
    --yaml ${DRONE_BASE_DIR}/.drone.yml \
    --in -

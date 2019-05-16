#!/bin/bash -e

###############################################################################
# Set up gcloud config for both local and CI/CD jobs
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

function gcloud_auth_user() {
  >&2 echo "Authenticating with personal credentials..."
	if ! gcloud auth list --format json | jq -er ".[] | select(.account == \"${USER}@example.com\") | .status == \"ACTIVE\"" > /dev/null 2>&1
  then
		gcloud auth login --brief
	fi

  # If REQUIRE_APPLICATION_DEFAULT_CREDENTIALS AND
  # file application_default_credentials.json is missing, 
  # set application-default-credentials
  if not_empty_var REQUIRE_APPLICATION_DEFAULT_CREDENTIALS \
    && [ ! -f ~/.config/gcloud/application_default_credentials.json ]
  then 
      >&2 echo "Set application-default-credentials with personal credentials..."
      gcloud auth application-default login
  fi
}

function gcloud_auth_service_account() {
  key_file=$1
  >&2 echo "Authenticating with service account credentials..."
	gcloud auth activate-service-account --key-file ${key_file}
  # set application-default-credential
  mkdir -p ~/.config/gcloud
  cp -f ${key_file} ~/.config/gcloud/application_default_credentials.json
}

function gcloud_config() {
  >&2 echo "Set up gcloud configurations..."
  empty_var GCP_CONFIGURATION && GCP_CONFIGURATION=default

  if ! gcloud config configurations describe ${GCP_CONFIGURATION} &> /dev/null
  then
    # create a new gcloud conf if doesn't exist
    gcloud config configurations create --activate ${GCP_CONFIGURATION}
  else
    # activate config
    gcloud config configurations activate ${GCP_CONFIGURATION}
  fi

  # try set config from environment variables (env.mk)
  gcloud config set project ${GCP_PROJECT_ID} > /dev/null 2>&1
  gcloud config set core/disable_usage_reporting False > /dev/null 2>&1
  not_empty_var GCP_REGION && gcloud config set compute/region ${GCP_REGION} > /dev/null 2>&1
  not_empty_var GCP_ZONE && gcloud config set compute/zone ${GCP_ZONE} > /dev/null 2>&1
}

GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT:-}
GCP_PROJECT_ID=${GCP_PROJECT_ID:-$GOOGLE_CLOUD_PROJECT}
if empty_var GCP_PROJECT_ID
then
  >&2 echo "ERROR: GCP_PROJECT_ID is missing."
  exit 1
fi

NON_INTERACTIVE=${NON_INTERACTIVE:-false}

################################################################
# Go through all auth scenarios in the defined ORDER
################################################################

# Do gcloud config configurations
gcloud_config

# Auth with key in GCP_KEY, the value may be base64 encoded
# Used in case of CI/CD job
if not_empty_var GCP_KEY
then 
  >&2 echo "Get GCP Key from GCP_KEY."
  key_file=$(mktemp)
  # Default to use GCP_KEY as it is
  echo $GCP_KEY > $key_file
  if echo $GCP_KEY | base64 --decode &> /dev/null ; then
    echo $GCP_KEY | base64 --decode > $key_file
  fi
  gcloud_auth_service_account $key_file
  rm -f $key_file
  exit 0
fi

# Auth with key in GCP_KEY_BASE64, the value must be base64 encoded
if not_empty_var GCP_KEY_BASE64
then 
  >&2 echo "Get GCP Key from GCP_KEY_BASE64."
  key_file=$(mktemp)
  echo $GCP_KEY_BASE64 | base64 --decode > $key_file
  gcloud_auth_service_account $key_file
  rm -f $key_file
  exit 0
fi

# Set DEFAULT_GCP_KEY_FILE 
if not_empty_var GCP_KEY_PATH
then
  DEFAULT_GCP_KEY_FILE=${HOME}/.vault-local/${GCP_KEY_PATH}.json
else
  DEFAULT_GCP_KEY_FILE=${HOME}/.vault-local/unknown
fi

# If GCP_KEY_FILE is not defined, use DEFAULT_GCP_KEY_FILE
GCP_KEY_FILE=${GCP_KEY_FILE:-$DEFAULT_GCP_KEY_FILE}

# If $NON_INTERACTIVE is true and gcp key is in $GCP_KEY_FILE
if [ "$NON_INTERACTIVE" = true ] && [ -f $GCP_KEY_FILE ] 
then 
  echo gcloud_auth_service_account $GCP_KEY_FILE
  exit 0
fi

# Auth with personal credentials
if ( not_empty_var user_auth && [ "$user_auth" = true ] ) \
  || ( not_empty_var GCP_USER_AUTH && [ "$GCP_USER_AUTH" = true ] )
then
  gcloud_auth_user
  exit 0
fi

# Auth with the key from vault GCP_KEY_PATH
# Cache the key in local GCP_KEY_PATH to avoid pull from slow vault.
if not_empty_var GCP_KEY_PATH
then 
  if [ ! -f $GCP_KEY_FILE ]
  then 
    $THIS_DIR/vault-login.sh
    mkdir -p $(dirname "$GCP_KEY_FILE")
    $THIS_DIR/vault-read.sh $GCP_KEY_PATH > $GCP_KEY_FILE
  fi
  gcloud_auth_service_account $GCP_KEY_FILE
  exit 0
fi

# Catch All
gcloud_auth_user

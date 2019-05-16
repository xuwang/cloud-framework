#!/bin/bash

###############################################################################
# Register zone name IP
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

# fail on error or undeclared vars
trap_errors

TRAN_FILE=/tmp/transaction.yaml
ZONE=$1  # e.g. example-zone
NAME=$2
set +u # optional vars
IP=${3:-${SERVICE_IP}}
TTL=${4:-300}
set -u

# ensure trailing period (remove and add)
NAME=${NAME%*.}.

if existing_record=$(gcloud dns record-sets list --format json -z ${ZONE} | jq -ec ".[] | select( .name == \"${NAME}\" and .type == \"A\")"); then
  existing_ip=$(echo "$existing_record" | jq -er ".rrdatas[0]")
  existing_ttl=$(echo "$existing_record" | jq -er ".ttl")

  if [ "${existing_ip}" = "${IP}" ]; then
    echo "${NAME} already registered with IP ${existing_ip}"
    exit
  fi

  echo "change DNS register zone=${ZONE} name=${NAME} from ${existing_ip} to ${IP}"
  gcloud dns record-sets transaction start -z ${ZONE} --transaction-file ${TRAN_FILE}
  gcloud dns record-sets transaction remove -z ${ZONE} --transaction-file ${TRAN_FILE} --name ${NAME} --ttl ${existing_ttl} --type A ${existing_ip}
  gcloud dns record-sets transaction add -z ${ZONE} --transaction-file ${TRAN_FILE} --name ${NAME} --ttl ${TTL} --type A ${IP}
  gcloud dns record-sets transaction execute -z ${ZONE} --transaction-file ${TRAN_FILE}
  rm -f ${TRAN_FILE}
else
  echo "DNS register zone=${ZONE} name=${NAME} ip=${IP}"
  gcloud dns record-sets transaction start -z ${ZONE} --transaction-file ${TRAN_FILE}
  gcloud dns record-sets transaction add -z ${ZONE} --transaction-file ${TRAN_FILE} --name ${NAME} --ttl ${TTL} --type A ${IP}
  gcloud dns record-sets transaction execute -z ${ZONE} --transaction-file ${TRAN_FILE}
  rm -f ${TRAN_FILE}
fi

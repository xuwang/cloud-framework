#!/bin/bash

###############################################################################
# Get IP address for a kubernetes service
###############################################################################

TYPE=$1    # svc or ing
ING_OR_SVC=$2
RETRY=20

until [[ $RETRY -eq 0 ]] || [[ ! -z ${IP} && ${IP} != 'null' ]]
do
  # echo counting down: $RETRY
  let "RETRY--"
  IP=$(kubectl get ${TYPE} ${ING_OR_SVC} -o json 2>/dev/null | jq -r '.status.loadBalancer.ingress[0].ip')
  sleep 2
done

echo ${IP}

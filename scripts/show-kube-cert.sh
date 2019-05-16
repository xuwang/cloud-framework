#!/bin/bash
# Usage:
#   show-kube-cert.sh [namespace] [secname]
# Show the x509 certificates stored in kubernetes secrets 

if [ -z "$1" ]
then
    sec_ns=default
else
    sec_ns=$1
    shift
fi

if [ -z "$1" ]
then
    sec_names=$(kubectl get secrets -o json  -n ${sec_ns} | jq -r '.items[].metadata.name')
else 
    sec_names=$*
fi

for sec in $sec_names
do
    crt=$(kubectl get secret -n ${sec_ns} ${sec} -o json | jq -r '.data."tls.crt"')
    if [ "null" != "${crt}" ] ; then
        echo  ========================= ${sec} ==============================
        echo $crt | base64 --decode \
            | openssl x509 -text \
            | sed '/BEGIN CERTIFICATE/,/END CERTIFICATE/d' \
            | sed '/Public Key Info/,/Exponent:/d' \
            | sed '/X509v3 Certificate Policies/,$d'
        echo  ========================= ${sec} ==============================
        echo
    fi
done
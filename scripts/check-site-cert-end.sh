#!/bin/sh
# Check whether the cert expires in the next days
#
function usage() {
    echo "Check whether the cert expires in the next days, exit 1 if so, 0 if not"
    echo "Usage: $0 <site addr>:<port> <days>"
}

if [ $# -eq 2 ] ; then
    echo \
    | openssl s_client -connect $1 2>/dev/null \
    | openssl x509 -noout -checkend $(echo 60*60*24*$2 | bc)
else
    usage
fi


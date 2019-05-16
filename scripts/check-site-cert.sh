#!/bin/sh
# Check TLS cert's issuer, subject, notBefore, and notAfter that's used on <addr>:<port>
#
function usage() {
    echo "Check TLS cert used on <addr>:<port>"
    echo "Usage: $0 <site addr>:<port>"
}

if [ ! -z "$1" ]; then
    echo \
    | openssl s_client -connect $1 2>/dev/null \
    | openssl x509 -noout -issuer -subject -dates
else
    usage
fi


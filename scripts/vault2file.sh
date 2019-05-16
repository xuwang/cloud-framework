#!/bin/bash
#
# Copy secrets from vault to files, the vault paths and file paths is defined in $1 file
# The file format is
#   <vault_path> <file_path> 

function copy_sec() {
    path=$1
    file=$2
    
    [[ -z "$path" ]] || [[ -z "$file" ]] && return

    mkdir -p $(dirname $2)
    vault-read.sh $path > $2
}

grep -v '^#' $1 | grep -v -e '^$' | render.sh |
while read -r line; do
    copy_sec $line
done

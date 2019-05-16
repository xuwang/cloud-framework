#!/bin/bash
#
# This scripts sync root repo's env.mk to sub-projects gcp-env.mk

THIS_DIR=$(dirname "$0")
SUB_PROJECTS=${SUB_PROJECTS:-sub-projects}

# include functions
source $THIS_DIR/functions.sh

function sync_env() {
    checkout_dir=$1
    if [ -f env.mk ]; then 
        if [ -d "$checkout_dir/common" ]; then 
            dest=common/gcp-env.mk
        elif [ -d "$checkout_dir/devOps" ]; then
            dest=devOps/gcp-env.mk
        else
            dest=gcp-env.mk
        fi
        git -C $checkout_dir pull -q
        echo Generating env.mk to $checkout_dir/$dest ...
        echo "# GENERATED GCP SHARED ENVIRONMENT VARIABLES. DO NOT EDIT." > $checkout_dir/$dest
        echo "# The source file is env.mk in the ${GCP_PROJECT_ID} repository." >> $checkout_dir/$dest
        echo "# If it is changed, re-run 'make sync-env' in ${GCP_PROJECT_ID} repository." >> $checkout_dir/$dest
        echo "#" >> $checkout_dir/$dest
        cat env.mk >> $checkout_dir/$dest
        git -C $checkout_dir add $dest 
        git -C $checkout_dir commit -q -m "sync gcp-env.mk from root repo's env.mk [skip ci]"
        git -C $checkout_dir push -q
    fi
}

function sync_one_repo() {
    repo_uri=$1
    branch=$2

    # remove possible schema
    repo_uri=${repo_uri#*//}
    # get the domain 
    domain=$(echo $repo_uri | cut -d "/" -f1)
    # get repo path
    repo=$(echo $repo_uri | cut -d "/" -f2-)
    # get the basename of the repo
    checkout_dir=$(basename $repo_uri)
    # remove possible file ext
    checkout_dir=${checkout_dir%.*}
    # if any is empty, skip
    [[ -z "$domain" ]] || [[ -z "$repo" ]] || [[ -z "$checkout_dir" ]]  && continue

    checkout_dir=${SUB_PROJECTS}/${checkout_dir%.*}
    if [ -e $checkout_dir ]
    then
        # sync sub-project gcp-env.mk 
        sync_env $checkout_dir
    fi
}

function sync_repos() {
    repos_file=$1
    grep -v '^#' $repos_file | grep -v -e '^$' |
    while read -r line; do
        sync_one_repo $line
    done
    true
}

try sync_repos $1

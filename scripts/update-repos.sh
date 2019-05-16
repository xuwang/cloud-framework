#!/bin/bash
#
# This scripts clone/update git repos defined in <repos.txt>.
# the <repos.txt> file is passed in by $1 and 
# must be in exact this format:
#   <git repo domain>/<namespaces>/<repo name>   <branch>
# 
# all repos will be cloned/pulled to sub-projects dir

THIS_DIR=$(dirname "$0")
SUB_PROJECTS=${SUB_PROJECTS:-sub-projects}

# include functions
source $THIS_DIR/functions.sh

function update_one_repo() {
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
    if [ ! -e $checkout_dir ]
    then
        echo Clone git@$domain:$repo to $checkout_dir ...
        git clone -q git@$domain:$repo $checkout_dir
        if [ ! -z $branch ]
        then 
            echo Checkout branch $branch
            git -C $checkout_dir fetch -q
            git -C $checkout_dir checkout -q $branch
        fi
    else
        echo Updating $checkout_dir ...
        git -C $checkout_dir fetch -q
        git -C $checkout_dir pull
    fi
}

function update_repos() {
    repos_file=$1
    grep -v '^#' $repos_file | grep -v -e '^$' |
    while read -r line; do
        update_one_repo $line
    done
    true
}

update_repos $*
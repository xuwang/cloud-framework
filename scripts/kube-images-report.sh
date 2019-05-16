#!/bin/bash

###############################################################################
# Do a helm install with a values file processed by gomplate
###############################################################################

THIS_DIR=$(dirname "$0")

# include functions
source $THIS_DIR/functions.sh

trap_errors

check_image() {
    local image_version=$1

    # we need to add latest if not there
    if [[ "$image_version" != *":"* ]]; then
        image_version=$image_version:latest
    fi

    # we need to add library/ if no slashes
    slashes="${image_version//[^\/]}"
    if [ ${#slashes} == 0 ]; then
        image_version=library/$image_version
    fi

    # we know it's dockerhub if only 1 or 0 slash
    if [ ${#slashes} -lt 2 ]; then
        dockerhub=true
    else
        dockerhub=false
    fi

    image=$(echo $image_version | cut -d : -f1)
    tag=$(echo $image_version | cut -d : -f2)
    echo "'${image_version}':"
    if [[ $image == "gcr"* ]]; then
        if tag_datetime=$(gcloud --format json alpha container images list-tags $image --limit 1000 --filter "tags =( \"$tag\" )" 2> /dev/null | jq -er .[].timestamp.datetime); then
            results=false
            for new_tag in $(gcloud --format "value(tags)" alpha container images list-tags $image --limit 1000 --filter "timestamp.datetime > \"$tag_datetime\" AND tags :(*)"); do
                results=true
                echo "- ${new_tag}"
            done
            if [ "$results" = "false" ]; then
                echo "- (no newer tags)"
            fi
        else
            >&2 echo "- can't list image tags for '$image' (probably auth issue)"
        fi
    elif [[ $image == "registry.access.redhat.com"* ]]; then
        # do special / replace since redhat has slashes in the image name and escapes them
        escaped_image="$(echo ${image%/*}%252F${image##*/})"
        tags=$(curl --fail -s "https://www.redhat.com/wapps/containercatalog/rest/v1/repository/${escaped_image}/images" \
            | jq -ec '.processed[].images[].repositories[].tags')
        tag_datetime=$(echo "$tags" | jq -r ".[] | select( .name == \"$tag\") | .added_date")
        echo $tags | jq -c ".[] | select(.added_date > \"$tag_datetime\")" | while read -r new_tag_json; do
            new_tag_name=$(echo $new_tag_json | jq -er .name)
            echo "- $new_tag_name"
        done
    elif [ "$dockerhub" = "true" ]; then
        tags=$(curl --fail -sL "https://registry.hub.docker.com/v2/repositories/${image}/tags?page_size=1024" | jq -cr ".results")
        tag_datetime=$(echo $tags | jq -er ".[] | select(.name == \"$tag\") | .last_updated ")
        if echo $tags | jq -er ".[] | select(.last_updated > \"$tag_datetime\")" > /dev/null 2>&1; then
            echo $tags | jq -c ".[] | select(.last_updated > \"$tag_datetime\")" | while read -r new_tag_json; do
                new_tag_name=$(echo $new_tag_json | jq -er .name)
                echo "- $new_tag_name"
            done
        else
            echo "- (no newer tags)"
        fi
    else
        >&2 echo "- ERROR: repository for '$image' not supported in this script"
    fi
}

# we want to see all images, except for those in kube-system

# tiller is special case, something we maintain in kube-system
tiller_image_version=$(kubectl get pods --all-namespaces --selector=name=tiller -o jsonpath="{..image}")
if [ ! -z "$tiller_image_version" ]; then
    echo "---------------------------------"
    echo "NAMESPACE 'kube-system':"
    echo "---------------------------------"
    check_image $tiller_image_version
fi

for ns in $(kubectl --all-namespaces -o jsonpath="{..name}" get ns | tr -s '[[:space:]]' '\n' | grep -v kube-system ); do
    echo "---------------------------------"
    echo "NAMESPACE '$ns':"
    echo "---------------------------------"
    
    for image_version in $(kubectl get pods -n $ns -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq); do
        check_image $image_version 
    done
done
#!/bin/bash

###############################################################################
# Downloads needed binaries to run
###############################################################################

# include functions
THIS_DIR=$(dirname "$0")
source $THIS_DIR/functions.sh

BASE_DEPS_REQ_FILE=$THIS_DIR/../dependencies/base-requirements.txt

trap_errors

# check is optional
set +u
check=${1:-false}
set -u

if [ "$check" = "check" ]; then
    check=true
fi

# make sure DEPS_DIR is set up, otherwise create it
if [ -z "$DEPS_DIR" ]; then
    >&2 echo "$0: env var DEPS_DIR must be set!"
    exit 1
fi

if ! [ -d "$DEPS_DIR" ]; then
    >&2 echo "$0: $DEPS_DIR does not exist, creating with mkdir -p"
    mkdir -p $DEPS_DIR
fi

# choose deps definition file from OSTYPE
if [[ "$OSTYPE" == "darwin"* ]]; then
    DEPS_DEF_FILE=$THIS_DIR/../dependencies/deps-mac.txt
else
    DEPS_DEF_FILE=$THIS_DIR/../dependencies/deps-other.txt
    >&2 echo "NOTE: AUTOMATIC INSTALL OF DEPENDENCIES ONLY SUPPORTED FOR MAC OS"
    >&2 echo
fi

in_path() {
    local name="$1"
    command -v $name > /dev/null 2>&1
}

# find deps requirements file for project (individual repo requirements)
if [ -f .deps.txt ]; then
    DEPS_REQ_FILE=.deps.txt
elif [ -f ../.deps.txt ]; then
    DEPS_REQ_FILE=../.deps.txt
else
    DEPS_REQ_FILE=
fi

has_version() {
    local name="$1"
    local version_search_text="$2"

    if [ "$version_search_text" = "none" ]; then
        if ! in_path $name; then
            >&2 echo "'$name' not in path"
            return 1
        fi
    else
        if version=$($name version -c 2>/dev/null); then
            method="version -c"
        else
            version=$($name --version 2>/dev/null)
            method=--version
        fi

        if echo $version | grep -vq $version_search_text; then
            >&2 echo "$name: version incorrect: required '$version_search_text' but get `$name $method`."
            return 1
        fi

    fi
}

# simply checks if the URL has changed since the last time we fetched the binary
has_binary_url() {
    local name="$1"
    local url="$2"

    if ! command -v $name > /dev/null 2>&1; then
        return 1
    fi

    if ! [ -f "$DEPS_DIR/$name.url" ]; then
        return 1

    fi
    [ "$(cat $DEPS_DIR/$name.url)" = "$url" ]
}

write_binary_url() {
    local name="$1"
    local url="$2"

    echo -n $url > $DEPS_DIR/$name.url
}

check() {
    local name="$1"
    local version_search_text="$4"

    if has_version $name $version_search_text; then
        if [ "$version_search_text" = "none" ]; then
            echo "$name: installed"
        else
            echo "$name: installed and at version $version_search_text"
        fi
    fi
}

fetch() {
    local name="$1"
    local type="$2"

    local url="$3"
    local version_search_text="$4"

    if has_version $name $version_search_text; then
        return
    fi

    if [ "$type" = "manual" ]; then
        >&2 echo "- install MANUALLY from the instructions at the following URL:"
        >&2 echo "     $url"

    elif [ "$type" = "url" ]; then
        echo "- installing $name $version_search_text to $DEPS_DIR/$name"
        curl -s -L -o $DEPS_DIR/$name "$url"

    elif [ "$type" = "url-zip" ]; then
        echo "- installing $name $version_search_text to $DEPS_DIR/$name"
        curl -s -L -o $DEPS_DIR/$name.zip "$url"
        unzip -q -o -j "$DEPS_DIR/$name.zip" -d $DEPS_DIR
        rm $DEPS_DIR/$name.zip

    elif [ "$type" = "url-tar-gz" ]; then
        echo "- installing $name $version_search_text to $DEPS_DIR/$name"
        curl -s -L -o $DEPS_DIR/$name.tar.gz "$url"

        # fancy stuff to detect if a file is in subdirectory, and just extract that file
        archive_binary_path=$(tar -tf $DEPS_DIR/${name}.tar.gz | grep -E $name)
        if ! [ $(dirname $archive_binary_path) = '.' ]; then
            strip_components_arg=--strip-components=1
        else
            strip_components_arg=
        fi
        if ! tar -xf $DEPS_DIR/$name.tar.gz $strip_components_arg -C $DEPS_DIR $archive_binary_path > /dev/null 2>&1; then
            tar -xvf $DEPS_DIR/$name.tar.gz $strip_components_arg -C $DEPS_DIR $archive_binary_path
        fi
        rm $DEPS_DIR/$name.tar.gz
    fi

    if [ -f $DEPS_DIR/$name ]; then
        chmod +x $DEPS_DIR/$name
    fi
}

while read -r line; do
    if [[ ${line:0:1} == '#' ]] || ! cat $BASE_DEPS_REQ_FILE $DEPS_REQ_FILE | grep -q ${line%% *}; then
        continue
    else
        if [ "$check" = "true" ]; then
            check $line
        else
            fetch $line
        fi
    fi

done < $DEPS_DEF_FILE

if [ "$check" = "false" ]; then
    >&2 echo
    >&2 echo "Installed all dependencies that can be AUTOMATICALLY installed"
    >&2 echo "- You must install any of the above items that are labeled 'install MANUALLY'"
    >&2 echo
fi

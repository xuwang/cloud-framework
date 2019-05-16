#!/bin/bash

###############################################################################
# convert stdin YAML to JSON
# requires gomplate
###############################################################################

cat - > /tmp/gomplate_in.yaml

gomplate -i '{{ (ds "input") | data.ToJSON }}' -d input=file:///tmp/gomplate_in.yaml

rm -f /tmp/gomplate_in.yaml
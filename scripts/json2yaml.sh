#!/bin/bash

###############################################################################
# convert stdin JSON to YAML
# requires gomplate
###############################################################################

cat - > /tmp/gomplate_in.json

gomplate -i '{{ (ds "input") | data.ToYAML }}' -d input=file:///tmp/gomplate_in.json

rm -f /tmp/gomplate_in.json
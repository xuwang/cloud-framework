#!/bin/bash

length=${1:-20}
pwgen $length 1 | tr -d '\n'
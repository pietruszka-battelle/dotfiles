#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env storage delete [options]" ''
	msg -- 'Options:'
	disp    :usage			--help -h
	disp    VERSION			--version -v
	param	ACCOUNT			--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

echo az storage container delete --name environments --account-name $ACCOUNT

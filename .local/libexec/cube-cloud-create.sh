#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube cloud create -n <NAME> [options...] | -h"
	param	NAME	-n --name	:init="$(az cloud show --query "name" -o tsv)"		-- "CUBE CLOUD Name defaults to $(az cloud show --query "name" -o tsv)"
	disp	:usage	-h --help
	msg -- '' 'Options:'
	param	ACCOUNT	-a --account init:="cubetfstateprod"	-- "CUBE State Storage Account Name (cubetfstateprod)"
}

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh

# Add workload to recfile
echo -n "Addding cloud to configuration data store..."
cube-env-download $ACCOUNT
recins -t cloud -f name -v $NAME environments.rec || die "Could not add cloud to recfile"
cube-env-upload $ACCOUNT
echo "done"
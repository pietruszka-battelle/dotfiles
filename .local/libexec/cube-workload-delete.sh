#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube workload delete <NAME>" ''
	msg -- 'Options:'
	disp	:usage		-h --help
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
	param	WORKLOAD_NAME		--name -n	-- "CUBE WORKLOAD Name"
}

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh

cat <<HERE
`divider`
Have made sure that ALL environments have been properly cleaned up? (y/N)
Maybe try this if you are not sure

cube workload status -n $WORKLOAD_NAME
`divider`
HERE

read key
[[ $key == "y" ]] || die

# Remove workload from recfile
cube-env-download $ACCOUNT
recdel -t workload -e "name = '$WORKLOAD_NAME'" environments.rec || die "Could not remove workload froe recfile"
cube-env-upload $ACCOUNT

#delete repo
/home/pietruszka/.local/libexec/cube-repo-delete.sh -n $WORKLOAD_NAME || die 'Could not delete a repo'



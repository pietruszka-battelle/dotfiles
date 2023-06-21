#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube workload list [options]" ''
	msg -- 'Options:'
	disp    :usage  -h --help
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

# Get workload recs from recfile
cube-env-download $ACCOUNT
echo "Repo to RecFile comparision:"
echo
echo -e "No Repo\tNo Rec\tGood"
comm \
	<(recsel -C -t workload -P name environments.rec | sort) \
	<(gh repo list battellecube --limit 1000 --topic workload --topic cube | awk '{print $1}' | awk -F'/' '{print $2}' | sort)

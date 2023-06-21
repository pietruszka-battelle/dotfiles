#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env	list [options]" ''
	msg -- 'Options:'
	disp    :usage  -h --help
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

# Get env recs from recfile
cube-env-download $ACCOUNT
echo 'Records:'
rec2csv -t environment environments.rec

echo
echo 'Repositories:'
#gh environment list battellecube --limit 1000 --topic workload --topic cube
echo
echo 'Deployed:'
az account list --query [].[id] -o tsv 2>/dev/null | \
	while read sub
	do 
		( az group list --subscription $sub --query [?tags.environment].[name,id] -o tsv ) &
	done | \
		awk -F'/' '{print $3, $1}' | \
		sort -k2

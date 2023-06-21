#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant config [options]... [commands]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help

	msg -- '' 'Commands:'
	cmd secure-cloud-sp -- "Creates the service principal used by the Secure Cloud File Exchange application"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		secure-cloud-sp)
			/home/pietruszka/.local/libexec/cube-tenant-config-secure-cloud-sp.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

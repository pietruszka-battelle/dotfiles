#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant sp [options]... [commands]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help

	msg -- '' 'Commands:'
	cmd list -- "List CUBE service principles"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		list)
			/home/pietruszka/.local/libexec/cube-tenant-sp-list.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

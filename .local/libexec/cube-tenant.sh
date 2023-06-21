#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant [options]... [commands]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help

	msg -- '' 'Commands:'
	cmd sp -- "Manage CUBE service principals"
	cmd user -- "Manage CUBE users"
	cmd create -- "Create tenant instance in recfile"
	cmd config -- "Configure new tenant for CUBE"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		sp)
			/home/pietruszka/.local/libexec/cube-tenant-sp.sh "$@"
			;;
		user)
			/home/pietruszka/.local/libexec/cube-tenant-user.sh "$@"
			;;
		create)
			/home/pietruszka/.local/libexec/cube-tenant-create.sh "$@"
			;;
		config)
			/home/pietruszka/.local/libexec/cube-tenant-config.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube cloud [options]... [arguments]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
	disp    VERSION    --version -v

	msg -- '' 'Commands:'
	cmd create -- "Creates a CUBE cloud"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		create)
			/home/pietruszka/.local/libexec/cube-cloud-create.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

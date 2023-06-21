#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube repo [options]... [command]" ''
	msg -- 'Options:'
	disp    :usage  -h --help
	disp    VERSION    --version

	msg -- '' 'Commands:'
	cmd mirror -- "Mirror repos"
	cmd create -- "Creates a CUBE git repository"
	cmd delete -- "Deletes a CUBE git repository"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		mirror)
			/home/pietruszka/.local/libexec/cube-repo-mirror.sh "$@"
			;;
		create)
			/home/pietruszka/.local/libexec/cube-repo-create.sh "$@"
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-repo-delete.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi


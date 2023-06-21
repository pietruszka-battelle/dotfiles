#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env storage [options]... <action> NAME" ''
	msg -- 'Options:'
	disp    :usage			--help -h
	disp    VERSION			--version -v
	msg -- 'Commands [choose one]'
	cmd create -- "Creates CUBE environment storage"
	cmd delete -- "Deletes CUBE environment storage"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		create)
			/home/pietruszka/.local/libexec/cube-env-storage-create.sh "$@"
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-env-storage-delete.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

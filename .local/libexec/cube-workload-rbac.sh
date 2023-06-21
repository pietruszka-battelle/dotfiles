#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage	-- "Usage: cube workload rbac [options]...[COMMAND]" ''
	msg -- 'Options:'
	disp    :usage		-h	--help

	msg -- '' 'Commands:'
	cmd create	-- 'Create rbac for workloads'
	cmd delete	-- 'Delete rbac for workload'

}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		create)
			/home/pietruszka/.local/libexec/cube-workload-rbac-create.sh $@
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-workload-rbac-delete.sh $@
			;;
		--) # no subcommand, arguments only
	esac
fi

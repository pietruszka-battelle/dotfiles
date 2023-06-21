#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube workload [options]...[COMMAND]" ''
	msg -- 'Options:'
	disp    :usage  -h --help

	msg -- '' 'Commands:'
	cmd create	-- 'Create a new workload'
	cmd delete	-- 'Delete a new workload'
	cmd list	-- 'List all workloads'
	cmd module	-- 'Manage workload modules'
	cmd rbac 	-- 'Manage rbac for workloads'
	cmd status	-- 'Show status of a workload'

}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		create)
			/home/pietruszka/.local/libexec/cube-workload-create.sh $@
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-workload-delete.sh $@
			;;
		list)
			/home/pietruszka/.local/libexec/cube-workload-list.sh $@
			;;
		module)
			/home/pietruszka/.local/libexec/cube-workload-module.sh $@
			;;
		rbac)
			/home/pietruszka/.local/libexec/cube-workload-rbac.sh $@
			;;	
		status)
			/home/pietruszka/.local/libexec/cube-workload-status.sh $@
			;;
		--) # no subcommand, arguments only
	esac
fi

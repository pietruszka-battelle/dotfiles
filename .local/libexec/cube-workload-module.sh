#!/usr/bin/env bash


latest_release() {
	local repo=$1
	local release_list=$(gh release list --repo "battellecube/$repo")
	echo $release_list | awk '/Latest/{print $1}'
}

releases() {
	git submodule foreach | awk '{print $2}' | tr -d "'"| awk -F/ '{print $2}'| while read r; do echo "$r=$(latest_release $r)"; done|grep -v '=$'
}


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage	-- "Usage: cube workload module [options]...[COMMAND]" ''
	msg -- 'Options:'
	disp    :usage		-h	--help
	flag	RELEASES		-r	init:@unset	-- "Show latest available release of each module"

	msg -- '' 'Commands:'
	cmd list	-- 'List all modules'
	cmd update	-- 'Update modules of a workload'
	cmd add		-- 'Add a module to a workload'

}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ ${RELEASES+is_set} ]; then
	releases
	exit
fi
if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		list)
			/home/pietruszka/.local/libexec/cube-workload-module-list.sh $@
			;;
		update)
			/home/pietruszka/.local/libexec/cube-workload-module-update.sh $@
			;;
		add)
			/home/pietruszka/.local/libexec/cube-workload-module-add.sh $@
			;;
		--) # no subcommand, arguments only
	esac
fi

#!/usr/bin/env bash

# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube [options]... [arguments]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
	disp    VERSION    --version -v

	msg -- '' 'Commands:'
	cmd env -- "Manages CUBE environments"
	cmd log -- "WIP: Currently just shows log setup information"
	cmd status -- "WIP: Shows environment status information"
	cmd repo -- "Manages CUBE repositories"
	cmd workload -- "Manages CUBE workloads"
	cmd create -- "Alias to workload create"
	cmd ci -- "Manage CI/CD activities for a CUBE"
	cmd tenant -- "Manage CUBE Azure tenant"
	cmd platform -- "Manage CUBE platforms"
	cmd cloud -- "Manage CUBE clouds"
}
# @end


eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		env)
			/home/pietruszka/.local/libexec/cube-env.sh "$@"
			;;
		log)
			/home/pietruszka/.local/libexec/cube-log.sh "$@"
			;;
		status)
		  /home/pietruszka/.local/libexec/cube-status.sh "$@"
			;;
		repo)
			/home/pietruszka/.local/libexec/cube-repo.sh "$@"
			;;
		workload)
			/home/pietruszka/.local/libexec/cube-workload.sh "$@"
			;;
		create)
			/home/pietruszka/.local/libexec/cube-workload-create.sh "$@"
			;;
		ci)
			/home/pietruszka/.local/libexec/cube-ci.sh "$@"
			;;
		tenant)
			/home/pietruszka/.local/libexec/cube-tenant.sh "$@"
			;;
		platform)
			/home/pietruszka/.local/libexec/cube-platform.sh "$@"
			;;
		cloud)
			/home/pietruszka/.local/libexec/cube-cloud.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

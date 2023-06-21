#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform [options]... [arguments]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
	disp    VERSION    --version

	msg -- '' 'Commands:'
	cmd create -- "Creates a CUBE platform"
	cmd delete -- "Deletes a CUBE platform"
	cmd set -- "Sets a CUBE platform local environment"
	cmd init -- "Terraform init platform"
	cmd apply -- "Terraform apply platform"
	cmd destroy -- "Terraform destroy platform"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		create)
			/home/pietruszka/.local/libexec/cube-platform-create.sh "$@"
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-platform-delete.sh "$@"
			;;
		set)
			/home/pietruszka/.local/libexec/cube-platform-set.sh "$@"
			;;
		init)
			/home/pietruszka/.local/libexec/cube-platform-init.sh "$@"
			;;
		apply)
			/home/pietruszka/.local/libexec/cube-platform-apply.sh "$@"
			;;
		destroy)
			/home/pietruszka/.local/libexec/cube-platform-destroy.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi

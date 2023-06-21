#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env apply [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
	flag	DEV		--dev -d -- "Use Development Settings"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-eval || die "cube-env-eval failed"
cube-env-validate || die "cube-env-validate failed"

if [ $DEV ]; then
		cube-workload-terraform-dev-apply || die "cube-workload-terraform-dev-apply failed"
	else
		cube-workload-terraform-apply || die "cube-workload-terraform-apply failed"
fi

#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env destroy [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-eval || die "cube-env-eval failed"
cube-env-validate ||  die "cube-env-validate failed"

[ $PLATFORM ] && {
	cube-platform-terraform-destroy || die "destroying platform environment failed"
} 

[ $PLATFORM ] || {
	cube-workload-terraform-destroy || die "destroying environment failed"
}

az storage blob delete --only-show-errors --account-name $account -c tfstate -n "$(cube-env-deployment-id)" --subscription "$(cube-env-platform-subscription-id)" || die "failed to delete $(cube-env-deployment-id) state storage blob"





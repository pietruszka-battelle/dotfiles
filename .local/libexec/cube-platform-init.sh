#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform init [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-platform-validate()
{
	local repo_name=$(cube-env-repo-name)

	local warnings

	[ "cube-platform" != $repo_name ] && {
		warnings="${warnings}Your deployment (cube-platform) does not match your current directory (${repo_name}).\n\n"
	}

	local branch_name=$(cube-env-branch-name)

	[ $name != $branch_name ] && {
		warnings="${warnings}Your environment name ($name) does not match your current branch (${branch_name}).\n\n"
	}

	[ "$(echo $warnings | wc -w)" -gt 0 ] && {
		echo -e "\n------- warnings --------\n\n$warnings \n\nIf your are sure this is what you want, press 'y' to continue.\n"

		read key
    [[ $key == "y" ]] || die "user aborted"
	} || {
		return 0
	}
}

cube-platform-terraform-init()
{
	terraform init -upgrade \
		-backend-config=key=${name} \
		-backend-config=subscription_id=${sub} \
		-backend-config=environment=usgovernment \
		-backend-config=storage_account_name=${account} \
		--reconfigure || die "terraform init failed"
}

cube-platform-eval || die "Failed to platform eval"
cube-platform-validate || die "Failed to validate platform"
cube-platform-terraform-init || die "Failed to platform terraform init"





#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env ungrant [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
	param	USERID		--uid -i	-- "User Id to add to the specified group"
	flag	USER		--user -u -- "Remove user from the users group"
	flag	ADMIN		--admin -a -- "Remove user from the admins group"
	flag	MANAGER		--manager -m -- "Remove user from the managers group"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-workload-remove-from-users-group()
{
	local user_id=$1

	az ad group member remove \
		--group cube-$workload-users \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-remove-from-users-group failed"
}

cube-workload-remove-from-admins-group()
{
	local user_id=$1

	az ad group member remove \
		--group cube-$workload-admins \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-remove-from-admins-group failed"
}

cube-workload-remove-from-managers-group()
{
	local user_id=$1

	az ad group member remove \
		--group cube-$workload-managers \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-remove-from-managers-group failed"
}

cube-env-eval || die "cube-env-eval failed"

[ $USER ] && {
	cube-workload-remove-from-users-group $USERID || die "cube-workload-remove-from-users-group failed"
} 

[ $ADMIN ] && {
	cube-workload-remove-from-admins-group $USERID || die "cube-workload-remove-from-admins-group failed"
}

[ $MANAGER ] && {
	cube-workload-remove-from-managers-group $USERID || die "cube-workload-remove-from-managers-group failed"
}

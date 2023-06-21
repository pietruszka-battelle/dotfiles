#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env grant [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
	param	USERID		--uid -i	-- "User Id to add to the specified group"
	flag	USER		--user -u -- "Add user to the users group"
	flag	ADMIN		--admin -a -- "Add user to the admins group"
	flag	MANAGER		--manager -m -- "Add user to the managers group"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-workload-add-to-users-group()
{
	local user_id=$1

	az ad group member add \
		--group cube-$workload-users \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-add-to-users-group failed"
}

cube-workload-add-to-admins-group()
{
	local user_id=$1

	az ad group member add \
		--group cube-$workload-admins \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-add-to-admins-group failed"
}

cube-workload-add-to-managers-group()
{
	local user_id=$1

	az ad group member add \
		--group cube-$workload-managers \
		--member-id $(az ad user list --upn ${user_id} | jq -r '.[].id') || die "cube-workload-add-to-managers-group failed"
}

cube-env-eval || die "cube-env-eval failed"

[ $USER ] && {
	cube-workload-add-to-users-group $USERID || die "cube-workload-add-to-users-group failed"
} 

[ $ADMIN ] && {
	cube-workload-add-to-admins-group $USERID || die "cube-workload-add-to-admins-group failed"
}

[ $MANAGER ] && {
	cube-workload-add-to-managers-group $USERID || die "cube-workload-add-to-managers-group failed"
}








#!/usr/bin/env bash

cube-env-recfile-gen()
{
	cat <<-HERE
	%rec: environment
	%key: id
	%auto: id
	%type: id uuid
	%type: workload rec workload
	%type: platform rec platform
	%mandatory: name platform cidr workload sub account
	%allowed: description
	%unique: name platform cidr workload sub account
	%constraint: cidr ~ '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(3[0-2]|[1-2][0-9]|[0-9]))$'

	%rec: workload
	%key: name
	%allowed: created

	%rec: platform
	%key: id
	%auto: id
	%type: id uuid
	%type: tenant rec tenant
	%mandatory: name cidr sub account tenant
	%allowed: description
	%unique: name cidr sub account tenant
	%constraint: cidr ~ '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(3[0-2]|[1-2][0-9]|[0-9]))$'

	%rec: tenant
	%key: id
	%type: id uuid
	%type: cloud rec cloud
	%mandatory: name cloud
	%allowed: description
	%unique: name cloud

	%rec: cloud
	%key: name
	%allowed: description

	HERE
}

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env storage create [options]" ''
	msg -- 'Options:'
	disp    :usage			--help -h
	disp    VERSION			--version -v
	param	ACCOUNT			--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

create_storage_account() {
	local sub=$(cube-env-platform-subscription-id)

	echo -e "\nThe storage account specifed ($ACCOUNT) does not exist and will be created\n"
	echo -e "If you want to continue press 'y'\n"
	read key
    [[ $key == "y" ]] || exit 3

    az storage account create -n $ACCOUNT -g cube-state --subscription $sub
}

[[ $(az storage account check-name -n $ACCOUNT --query "nameAvailable" -o tsv) == "true" ]] && create_storage_account 


echo -e "\n---------WARNING---------WARNING---------\n"
echo -e "This will overwrite all of your environment data.\n"
echo -e "If you want to continue then press 'y'.\n"

echo
read key
[[ $key == "y" ]] || exit 3

echo -e "\n---------WARNING---------WARNING---------\n"
echo -e "Wait a minute...did you mean to click yes?\n"
echo -e "If you want to continue then press 'y'.\n"

echo
read key
[[ $key == "y" ]] || exit 3

az storage container create --name environments --account-name $ACCOUNT
az storage container create --name tfstate --account-name $ACCOUNT
cube-env-recfile-gen > environments.rec
cube-env-upload $ACCOUNT

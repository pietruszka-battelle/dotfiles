#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform create [options] -n <name>" ''
	param	NAME		-n --name							-- "CUBE Platform Name.  The value provided will have cube-platform prepended to it and that will be the actual platform name.  So if v0.1.0 is provided then cube-platform-v0.1.0 will be that actual platform name"
	msg -- 'Options:'
	disp	:usage		-h --help
	disp	VERSION		-v --version
	param	CIDR		-c --cidr -- "Platform Network CIDR"
	param	ACCOUNT		-a --account init:="cubetfstateprod" -- "CUBE State Storage Account Name (defaults to cubetfstateprod)"
}

source /home/pietruszka/.local/libexec/functions.sh

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

cube-platform-create-sp()
{
	local cit_security_subscription_id=$(cube-env-cit-security-subscription-id)
	local azure_dir_api_graph_id='00000003-0000-0000-c000-000000000000'
	local azure_dir_api_permission_id='19dbc75e-c2e2-444c-a770-ec69d8559fc7'

	log INFO "...granting platform service principal named ${name} 'Reader' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Reader"  \
			--scopes "/subscriptions/${cit_security_subscription_id}"  \
			--name "${name}" \
			--only-show-errors 1>/dev/null || die "Failed granting platform service principal name ${name} 'Reader' role for Log Analytics"

	log INFO "...granting platform service principal named ${name} 'Log Analytics Contributor' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Log Analytics Contributor" \
			--scopes "/subscriptions/${cit_security_subscription_id}" \
			--name "${name}" \
			--only-show-errors 1>/dev/null || die "Failed granting platform service principal named ${name} 'Log Analytics Contributor' role for Log Analytics"

	log INFO "...granting platform service principal named ${name} 'Owner' role for platform subscription"
	az ad sp create-for-rbac  \
			--output none \
			--role "Owner"  \
			--scopes "/subscriptions/$sub"  \
			--name "${name}" \
			--only-show-errors 1>/dev/null || die "Failed granting platform service principal named ${name} 'Owner' role for platform subscription"
}

make-platform-record()
{
	local name="cube-platform-$1"
	local cidr=$2
	local account=$3
	local sub=$(cube-env-platform-subscription-id)
	local tenant=$(current-tenant-id)

	cube-env-download $account

	matching_records=$(recsel -t platform -e "name = '$name' && tenant = '$tenant'" -p id environments.rec | wc -l)

	[[ $matching_records == 0 ]] || \
		{
			echo -e "\n---------WARNING---------WARNING---------\n"
			echo -e "\nPlatform record ${name} already exists.  Do you want to update it? \n\nIf you're sure, press 'y' to continue.\n"
			read key
			[[ $key == "y" ]] || die

			log INFO "cube-platform-create: WARNING: updating record name '$name'."
			TMPDIR=. recdel -t platform -e "name = '$name' && tenant = '$tenant'" environments.rec
		}

	# recutil 1.8 has bug preventing TMPDIR from being on another partition--our /tmp is this way
	TMPDIR=. recins --verbose \
			-t platform \
			-f name -v $name \
			-f cidr -v $cidr \
			-f sub -v $sub \
			-f account -v $account \
			-f tenant -v $tenant \
			environments.rec || die "make-platform-record: recins command failed"

	cube-env-upload $account || die "make-platform-record: cube-env-upload failed"
}

[ -z ${NAME} ] && die "name value must be provided"

make-platform-record $NAME $CIDR $ACCOUNT
cube-platform-set-local $NAME
cube-platform-create-sp

set-local-sp ${name}

log INFO "...successfully created cube-platform-${NAME} environment"

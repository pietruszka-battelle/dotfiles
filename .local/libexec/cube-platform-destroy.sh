#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform destroy [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-platform-terraform-vars()
{
	echo "-var=deployment_id=${name} \
		-var=subscription_id=${sub} \
		-var=security_subscription_id=$(cube-env-cit-security-subscription-id) \
		-var=address_space=${cidr} \
		-var=environment=usgovernment \
		-var=storage_endpoint=core.usgovcloudapi.net
		-var=sha=$(git rev-parse HEAD) \
		-var=tool_version=$(cube -v) \
		-var=tenant_id=${tenant} \
		-var=client_secret=$(cube-env-sp-client-secret) \
		-var=client_id=$(cube-env-sp-client-id)"
}

cube-platform-terraform-destroy()
{
	terraform destroy \
		$(cube-platform-terraform-vars) || die "terraform destroy failed"
}

cube-platform-eval || die "Failed to platform eval"
cube-platform-terraform-destroy || die "destroying platform environment failed"

az storage blob delete --only-show-errors --account-name $account -c tfstate -n $name --subscription $sub || die "failed to delete $name state storage blob"





#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant config secure-cloud-sp [options]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

. /home/pietruszka/.local/libexec/functions.sh

SC_SP_NAME="Secure Cloud File Exchange automated"

cube-env-secure-cloud-sp-id(){
	az ad sp list --all --filter "displayname eq '${SC_SP_NAME}'" --query "[].id" -o tsv || die "cube-env-secure-cloud-sp-id failed"
}

cube-env-create-secure-cloud-sp()
{
	local cit_security_subscription_id=$(cube-env-cit-security-subscription-id)

  	echo "...granting service principal 'Reader' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Reader"  \
			--scopes "/subscriptions/${cit_security_subscription_id}"  \
			--name "${SC_SP_NAME}" \
			--only-show-errors 1>/dev/null || die "granting service principal 'Reader' role for Log Analytics failed"

	echo "...granting service principal 'Log Analytics Contributor' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Log Analytics Contributor" \
			--scopes "/subscriptions/${cit_security_subscription_id}" \
			--name "${SC_SP_NAME}" \
			--only-show-errors 1>/dev/null || die "granting service principal 'Log Analytics Contributor' role for Log Analytics failed"
	
	local sp_id=$(cube-env-secure-cloud-sp-id)

	local directory_read_all_role_id=$(az ad sp show  --id 00000003-0000-0000-c000-000000000000  --query "appRoles[?value=='Directory.Read.All'].id"  -o tsv)
	echo "...granting service principal Directory.Read.All permission and granting admin consent"
	az rest --method post \
		--headers '{"Authorization": "Bearer '"$(cube-env-get-graph-token)"'"}' \
		--url https://graph.microsoft.us/v1.0/servicePrincipals/$sp_id/appRoleAssignments \
		--body '{"principalId":"'"$sp_id"'","resourceId":"'"$(cube-env-get-graph-id)"'","appRoleId":"'"$directory_read_all_role_id"'"}' \
		--only-show-errors 1>/dev/null || die "granting Directory.Read.All on ${SC_SP_NAME} failed"

	local user_read_role_id=$(az ad sp show  --id 00000003-0000-0000-c000-000000000000  --query "appRoles[?value=='User.Read.All'].id"  -o tsv)
	echo "...granting service principal User.Read permission and granting admin consent"
	az rest --method post \
		--headers '{"Authorization": "Bearer '"$(cube-env-get-graph-token)"'"}' \
		--url https://graph.microsoft.us/v1.0/servicePrincipals/$sp_id/appRoleAssignments \
		--body '{"principalId":"'"$sp_id"'","resourceId":"'"$(cube-env-get-graph-id)"'","appRoleId":"'"$user_read_role_id"'"}' \
		--only-show-errors 1>/dev/null || die "granting User.Read.All on ${SC_SP_NAME} failed"
}

cube-env-create-secure-cloud-sp

log INFO "Secure Cloud SP created successfully"
#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant sp list [options]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

az_ad_app_list() {
	# useful for testing
	#az ad app list --filter "displayname eq 'q-b-mccubeface-remoteapp'" --query "[].id" -o tsv
	az ad app list --all --query "[].id" -o tsv
}

az_ad_app_display_name() {
	az ad app show --id $1 --query "displayName" -o tsv 2>/dev/null 
}

az_ad_app_active_credential_count() {
	az ad app show --id $1 --query 'length(passwordCredentials)'
}

az_ad_app_owner() {
	az ad app owner list --id $1 --query "[0].mail" -o tsv 2>/dev/null
}

print_row() {
	local __row="$(az_ad_app_display_name $1)"
	__row+=", $(az_ad_app_owner $1)"
	__row+=", $1"
	__row+=", $(az_ad_app_active_credential_count $1)"
	echo $__row
}

echo "SP Name, SP Owner, SP ID, Credential Count"
for id in $(az_ad_app_list) 
do
	((i=i+1))
	print_row $id &
	pids[i]=$!
	while [ $(pgrep -c -P$$) -ge 10 ]; do sleep 0.1; done
done
wait "${pids[@]}"

# TODO work out a better way to callout details around group membership, role
# assignments, etc. Also need to convert most of these calls to use curl as
# each invocation of `az` spins up a complete python env and crushes the
# machine which is why I needed to add the poor man's worker pool in the main
# for loop

#az ad app list
# az ad sp list --query '[].servicePrincipalNames[0]' -o tsv
# for sub in $(az account list --query [].id -o tsv); do (az role assignment list --assignee sandman@battelle.us --scope /subscriptions/$sub --query '[].[roleDefinitionName, scope]' -o tsv) & done

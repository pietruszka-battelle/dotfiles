#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube tenant user list [options]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

. /home/pietruszka/.local/libexec/functions.sh

az_ad_user_list() {
	# useful for testing
	#az ad user list --filter "userPrincipalName eq 'sandman@battelle.us'" --query "[].[displayName, userPrincipalName]" -o tsv
	az ad user list --query "[].[displayName, userPrincipalName]" -o tsv
}

az_ad_user_groups() {
	az ad user get-member-groups --id $1 -o tsv |awk -F'\t' '{print $2,$1}'
}

print_row() {
	divider '='
	echo "$1 <$2>"
	divider
	az_ad_user_groups $2
}

az_ad_user_list | while IFS=$'\t' read display_name principal_name
do
	print_row "$display_name" $principal_name
done

# TODO work out a better way to callout details around group membership, role
# assignments, etc. Also need to convert most of these calls to use curl as
# each invocation of `az` spins up a complete python env and crushes the
# machine which is why I needed to add the poor man's worker pool in the main
# for loop

#az ad app list
# az ad sp list --query '[].servicePrincipalNames[0]' -o tsv
# for sub in $(az account list --query [].id -o tsv); do (az role assignment list --assignee sandman@battelle.us --scope /subscriptions/$sub --query '[].[roleDefinitionName, scope]' -o tsv) & done

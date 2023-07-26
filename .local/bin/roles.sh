#!/bin/bash

echo "---> Logging into gov"
az logout
az cloud set --name AzureUSGovernment
az login --tenant battelle.us --allow-no-subscriptions --only-show-errors --output none

get_signed_in_user_id () {
	az ad signed-in-user show --query "id" --output tsv
}

get_signed_in_user_upn () {
	az ad signed-in-user show --query "userPrincipalName" --output tsv
}

get_ad_roles () {
	user_id=$1
	az rest --method get --url "https://graph.microsoft.us/beta/rolemanagement/directory/transitiveRoleAssignments?\$count=true&\$filter=principalId eq '$user_id'" --headers "ConsistencyLevel=Eventual" --query "value"
}

get_global_administrator_id () {
	az rest --method get --url "https://graph.microsoft.us/v1.0/roleManagement/directory/roleDefinitions" --query "value[?displayName=='Global Administrator'].id" --output tsv
}

user_id=$(get_signed_in_user_id)
user_upn=$(get_signed_in_user_upn)
ga_id=$(get_global_administrator_id)
ga_assigned=$(get_ad_roles $user_id | jq --arg ga_id "$ga_id" 'any(.roleDefinitionId == $ga_id)')
cube_nerds_assignments=$(az role assignment list --all --include-groups --include-inherited --assignee $user_upn --query "[?principalName == 'CUBE Nerds'] | length(@)")

if [ "$cube_nerds_assignments" -lt 1 ]; then
	echo "CUBE Nerds is not assigned..."
	read -r -p "Do you want to check out CUBE Nerds? [y/N] " response
	response=${response,,}
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		echo "launching cube nerds checkout"
		Activate-PIMRole.ps1 -aadGroup "\""CUBE Nerds"\""
	else
		echo "not launching cube nerds checkout, moving on"
	fi
else
	echo "CUBE Nerds is already assigned"
fi

if [ $ga_assigned = "false" ]; then
	echo "GA is not assigned..."
	read -r -p "Do you want to check out GA? [y/N] " response
	response=${response,,}
	if [[ "$response" =~ ^(yes|y)$ ]]; then
		echo "launching GA checkout"
		Activate-PIMRole.ps1 -aadRole "\""Global Administrator"\""
	else
		echo "not launching GA checkout, moving on"
	fi
else
	echo "GA is already assigned"
fi

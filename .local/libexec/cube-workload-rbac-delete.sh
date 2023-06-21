#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env rbac [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
  param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
	param	WORKLOAD_NAME	-n --name init:@unset	-- 'The name of the workload'
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh

[ ${WORKLOAD_NAME+set} ] || die "You must provide a WORKLOAD_NAME [-n | --name]"

log INFO "---> Check for existence of group: cube-$WORKLOAD_NAME-users"
group_count=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$WORKLOAD_NAME-users'" --query "length(value)") || log WARN "Failed to query for cube-$WORKLOAD_NAME-users group"
group_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$WORKLOAD_NAME-users'" --query "value[].id" --output tsv) || log WARN "Failed to get group id"
if [ $group_count -eq 1 ]
then
  log INFO "Group found, starting deletion process..."
  gcchigh_product_sku=$(az rest --method get --url "https://graph.microsoft.us/v1.0/subscribedSkus" --query "value[?appliesTo=='User']|[?skuPartNumber=='SPE_E5_USGOV_GCCHIGH'].skuId" -o tsv) || log WARN "Failed to retrieve Microsoft 365 E5 GCCHIGH sku id"

  log INFO "---> Check if Microsoft 365 E5 GCCHIGH license is applied to group"
  matched_sku=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups/$group_id?\$select=assignedLicenses" --query "assignedLicenses[?skuId=='$gcchigh_product_sku'] | length(@)") || log WARN "Failed checking for license on group"
  if [ $matched_sku -eq 1 ]
  then
    log INFO "Removing assigned license before group deletion..."
    az rest --method post \
      --url "https://graph.microsoft.us/v1.0/groups/$group_id/assignLicense" \
      --body '{"addLicenses": [],"removeLicenses": ["'$gcchigh_product_sku'"]}' -o none || log WARN "Failed to remove Microsoft 365 E5 GCCHIGH license to group"
  elif [ $matched_sku -eq 0 ]
  then
    log WARN "---> No license assigned, continuing..."
  else
    log WARN "Something went wrong removing licensing from the group"
  fi
  log INFO "Deleting group..."
  az rest --method delete --url "https://graph.microsoft.us/v1.0/groups/$group_id" || log WARN "Failed to delete group"
elif [ $group_count -eq 0 ]
then
  log WARN "Group not found, exiting..."
elif [ $group_count -gt 1 ]
then
  log WARN "More than 1 group found with this name, exiting..."
fi

az ad group delete --only-show-errors -g "cube-$WORKLOAD_NAME-admins"
az ad group delete --only-show-errors -g "cube-$WORKLOAD_NAME-managers"

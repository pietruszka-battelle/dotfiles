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

echo "---> Check for existence of group: cube-$WORKLOAD_NAME-users"
group_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$WORKLOAD_NAME-users'" --query "value[].id" --output tsv) || die "Failed to get group id"

echo "---> Checking whether team is ready to be used"
group_creation=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$WORKLOAD_NAME-users'" --query "value[].createdDateTime" --output tsv) || die "Failed to get group creation time"
suggested_retry=$(date -d "$group_creation 15 minutes" +'%x %X %Z')

az rest --method get --url https://graph.microsoft.us/beta/groups/$group_id?%24select=allowExternalSenders%2CautoSubscribeNewMembers > /dev/null 2>&1 || die "Team is not ready, this operation can take ~15 minutes. Exiting for now but try running again at $suggested_retry..."

gcchigh_product_sku=$(az rest --method get --url "https://graph.microsoft.us/v1.0/subscribedSkus" --query "value[?appliesTo=='User']|[?skuPartNumber=='SPE_E5_USGOV_GCCHIGH'].skuId" -o tsv) || die "Failed to retrieve Microsoft 365 E5 GCCHIGH sku id"

echo "---> Check if Microsoft 365 E5 GCCHIGH license is applied yet"
matched_sku=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups/$group_id?\$select=assignedLicenses" --query "assignedLicenses[?skuId=='$gcchigh_product_sku'] | length(@)")
if [ $matched_sku -eq 0 ]
then
  echo "---> Assigning Microsoft 365 E5 GCCHIGH license to group"
  az rest --method post \
    --url "https://graph.microsoft.us/v1.0/groups/$group_id/assignLicense" \
    --body '{"addLicenses": [{"disabledPlans": [],"skuId": "'$gcchigh_product_sku'"}],"removeLicenses": []}' -o none || die "Failed to assign Microsoft 365 E5 GCCHIGH license to group"
elif [ $matched_sku -eq 1 ]
then
  echo "License already assigned, skipping"
else
  die "Something went wrong applying licensing to the group"
fi

echo "---> Checking if mail transport rules need created"
if [ -e ./mail.txt ]
then
  echo "Mail file exists"
  domains=$(<./mail.txt)
  domains="\""$domains"\"" # surround variable contents with double quotes, powershell wants this
  /home/pietruszka/.local/libexec/exchange-config.ps1 -Workload $WORKLOAD_NAME -WhitelistDomains "$domains"
else
  echo "Mail file does not exist"
fi

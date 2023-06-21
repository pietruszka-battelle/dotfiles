#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env rebuild-vm" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-eval || die "Failed to call cube-env-eval, maybe try a cube env set"

resource_group="$workload-$name"

hostpool_name=$(az rest --method get --url "https://management.usgovcloudapi.net/subscriptions/$sub/resourceGroups/$resource_group/providers/Microsoft.DesktopVirtualization/hostPools?api-version=2022-02-10-preview" --query "value[].name" --output tsv) || die "Failed to get hostpool"
echo $hostpool_name

session_hosts=$(az rest --method get --url "https://management.usgovcloudapi.net/subscriptions/$sub/resourceGroups/$resource_group/providers/Microsoft.DesktopVirtualization/hostPools/$hostpool_name/sessionHosts?api-version=2022-02-10-preview" --query "value[].name" --output tsv) || die "Failed to get session hosts"
session_hosts=$(echo "$session_hosts" | cut -f 2 -d '/')

for s in $session_hosts
do
  echo "---> Deleting vm $s"
  disk_name=$(az vm show --name $s --resource-group $resource_group --query "storageProfile.osDisk.name" --output tsv)
  az vm delete --subscription $sub --resource-group $resource_group --name $s --yes || die "Failed to delete vm $s"
  echo "--->   Deleting disk $disk_name"
  az disk delete --subscription $sub --resource-group $resource_group --name $disk_name --yes || die "Failed to delete disk $disk_name"
  echo "--->   Removing session host $s"
  az rest --method delete --url "https://management.usgovcloudapi.net/subscriptions/$sub/resourceGroups/$resource_group/providers/Microsoft.DesktopVirtualization/hostPools/$hostpool_name/sessionHosts/$s?api-version=2022-02-10-preview" --output none || die "Failed to remove session host $s"
  echo "--->   Deleting device $s from AD"
  device_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/devices?\$filter=displayName%20eq%20'$s'" --query "value[].id" --output tsv)
  az rest --method delete --url "https://graph.microsoft.us/v1.0/devices/$device_id" || die "Failed to delete device $s from AD"

done

cube-workload-terraform-init || die
cube-workload-terraform-apply || die

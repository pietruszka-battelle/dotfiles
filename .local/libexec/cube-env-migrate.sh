#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env migrate [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
	param	SOURCE		--source -s	-- "Source environment"
	param	DESTINATION	--destination -d	-- "Destination environment"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-eval || die "cube-env-eval failed"

source_fslogix_sa=$(az storage account list --resource-group $SOURCE --query "[?starts_with(name,'fslogix')].name" -o tsv)
source_account_key="$(az storage account keys list -n ${source_fslogix_sa} --query "[0].value" -o tsv)"
source_containers="$(az storage container list --account-name ${source_fslogix_sa} --account-key $source_account_key --query "[].name" -o tsv)"

destination_fslogix_sa=$(az storage account list --resource-group $DESTINATION --query "[?starts_with(name,'fslogix')].name" -o tsv)
destination_account_key="$(az storage account keys list -n ${destination_fslogix_sa} --query "[0].value" -o tsv)"
destination_containers="$(az storage container list --account-name ${destination_fslogix_sa} --account-key $destination_account_key --query "[].name" -o tsv)"

dag_count=$(az desktopvirtualization applicationgroup list --resource-group $SOURCE --query "length(@)") || die "Failed to get count of application groups"

copy_status()
{
  az storage blob show --container-name $container --name $blob --account-key $destination_account_key --account-name $destination_fslogix_sa --query "properties.copy.status" -o tsv
}

user_session_count()
{
  az rest --method get --url https://management.usgovcloudapi.net/subscriptions/$sub/resourceGroups/$SOURCE/providers/Microsoft.DesktopVirtualization/hostPools/$SOURCE/userSessions?api-version=2022-07-05-preview --query "length(value)" || die "Failed to get count of user sessions"
}

if [ $(user_session_count) != 0 ]
then
  die "There are active sessions on the hostpool, log these users out before migrating"
else
  echo "There are no active sessions on the hostpool, continuing..."
fi

if [ $dag_count -eq 1 ]
then
  echo "Application group found, deleting..."
  dag_id=$(az desktopvirtualization applicationgroup list --resource-group $SOURCE --query "[0].id" --output tsv) || die "Failed to get application group id"
  az desktopvirtualization applicationgroup delete --ids $dag_id || die "Failed to delete application group"
elif [ $dag_count -gt 1 ]
then
  die "More than one application group found, exiting"
else
  echo "Application group not found, continuing..."
fi

for container in $source_containers
do
  #echo "Checking if $container exists..."
  if az storage container show --name $container --account-name $destination_fslogix_sa --account-key $destination_account_key > /dev/null 2>&1
  then
    echo "$container exists, not creating"
  else
    echo "$container does not exist, creating..."
    az storage container create --name $container --fail-on-exist --account-name $destination_fslogix_sa --account-key $destination_account_key --only-show-errors --output none || die "Container failed to create"

    blobs=$(az storage blob list --container-name $container --account-name $source_fslogix_sa --account-key $source_account_key --query "[].name" --only-show-errors --output tsv)
    for blob in $blobs
    do
      echo "---> Copying $blob"
      az storage blob copy start \
        --source-account-key $source_account_key \
        --source-account-name $source_fslogix_sa \
        --source-blob $blob \
        --source-container $container \
        --account-key $destination_account_key \
        --account-name $destination_fslogix_sa \
        --destination-blob $blob \
        --destination-container $container \
        --output none

      while [ $(copy_status) != "success" ]
      do
	echo "Copying..."
        sleep 5
      done
    done
    fi
done

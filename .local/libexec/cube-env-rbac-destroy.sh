#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env rbac [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-eval || die "Failed to call cube-env-eval"

DEPLOYMENT_ID=$(cube-env-deployment-id)
SUBSCRIPTION_ID=$(cube-env-workload-subscription-id)

dag_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$DEPLOYMENT_ID/providers/Microsoft.DesktopVirtualization/applicationgroups/${DEPLOYMENT_ID//.}-dag"
rg_id="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$DEPLOYMENT_ID"

echo "---> Starting terraform init/destroy"
platform_subscription_id=$(az account subscription list --only-show-errors --query "[?displayName=='cube-platform'].subscriptionId" --output tsv) || die "Failed to get platform subscription id"

terraform -chdir="./modules/terraform-cube-vdi/rbac" init -upgrade \
		-backend-config=key=$DEPLOYMENT_ID-rbac \
		-backend-config=subscription_id=$platform_subscription_id \
		-backend-config=environment=usgovernment \
		-backend-config=storage_account_name=${account} \
		--reconfigure || die "Failed to terraform init"
terraform -chdir="./modules/terraform-cube-vdi/rbac" destroy -var=workload_name=$workload -var=dag_id=$dag_id -var=rg_id=$rg_id || die "Terraform destroy failed"

echo "---> Deleting state blob"
az storage blob delete --only-show-errors --account-name $ACCOUNT -c tfstate -n "$(cube-env-deployment-id)-rbac" --subscription "$(cube-env-platform-subscription-id)" || die "failed to delete $(cube-env-deployment-id)-rbac state storage blob"

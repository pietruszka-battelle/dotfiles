#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube status" ''
	msg -- 'Options:'
	disp    :usage			--help -h
	disp    VERSION			--version -v
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
. /home/pietruszka/.local/libexec/functions.sh

log DEBUG "[Debugging enable]"

if [ -e .environment ]; then
  eval $(sed 's/: /=/'<.environment)
else
  WARNINGS="Environment not set \n\n"
fi

if [ -f .gitmodules ]; then
  SUBMODULES=$(cat .gitmodules  | grep "^\spath" | awk '{ print $3 }')
else
  SUBMODULES=''
fi

for i in $SUBMODULES
do
  if [ ! -f $i/.git ]; then
    WARNINGS="${WARNINGS}Submodule $i has not been initialized\n\nMaybe try:\n\n\tgit submodule update --init --recursive\n\n"
  fi
done

CLOUD_NAME=$(az account show --query environmentName -o tsv)

[[ $CLOUD_NAME == "AzureUSGovernment" ]] && {
    GRAPH_URL="https://graph.microsoft.us"
    LOCATION="usgovvirginia"
    ENVIRONMENT="usgovernment"
}

[[ $CLOUD_NAME == "AzureCloud" ]] || {
    GRAPH_URL="https://graph.microsoft.com"
    LOCATION="eastus"
    ENVIRONMENT="public"
}

PRODUCTION_TENANT_ID=215220de-12d7-408e-b764-7e998342ac42
DEVELOPMENT_TENANT_ID=b43c57c6-26f2-4956-8264-73fbc900fe90
TEST_TENANT_ID=5f810341-3d89-4a77-9202-bf2cf933ec1a
COMMERCIAL_PRODUCTION_TENANT_ID=2dd732a6-0413-473f-a1ce-68d1616444b6
PLATFORM_NAME=cube-platform

WORKLOAD_NAME=$(basename $(git remote get-url origin) .git)
BRANCH_NAME=$(git branch --show-current)

[[ $BRANCH_NAME == $name ]] || {
    WARNINGS="${WARNINGS}Your environment name does not match your BRANCH\n\nMaybe try:\n\n\tgit checkout $name\n\\n"
}

[[ $WORKLOAD_NAME == $workload ]] || {
    WARNINGS="${WARNINGS}Your workload does not match your current directory name\n\nMake sure you are in the correct project.\n\n"
}

DEPLOYMENT_ID=${workload}-${name}
DEPLOYMENT_SUBSCRIPTION_ID=$(az account subscription list --query "[?displayName=='$workload'].subscriptionId" -o tsv 2>/dev/null)
PLATFORM_SUBSCRIPTION_ID=$(az account subscription list --query "[?displayName=='$PLATFORM_NAME'].subscriptionId" -o tsv 2>/dev/null)
TENANT_ID=$(az account show -s $PLATFORM_SUBSCRIPTION_ID --query tenantId -o tsv) || {
    WARNINGS="${WARNINGS}\n\nMaybe try:\n\n\taz login -t battelle.us\n\n"
}
CURRENT_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
CURRENT_SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SECURITY_TENANT_ID=$TENANT_ID
SECUIRTY_SUBSCRIPTION_ID=$PLATFORM_SUBSCRIPTION_ID
BACKEND_STORAGE_ACCOUNT=XXXXXXX

[[ $DEPLOYMENT_SUBSCRIPTION_ID == $CURRENT_SUBSCRIPTION_ID ]] || {
    WARNINGS="${WARNINGS}Your subscription does not match the repository name. Do you really want to deploy to the '$CURRENT_SUBSCRIPTION_NAME' subscription and not the '$workload' subscription?.\nMaybe set your subscription to $workload like this: \n\n\taz account set -s $DEPLOYMENT_SUBSCRIPTION_ID\n"
    DEPLOYMENT_SUBSCRIPTION_ID=$CURRENT_SUBSCRIPTION_ID
}
[[ $ENV_NAME == 'main' ]] && {
    WARNINGS="${WARNINGS}Do you really want to be on the main branch.\n\n\tMaybe try: git checkout -b <branch name>\n\n"
}
[[ $TENANT_ID == $PRODUCTION_TENANT_ID ]] && {
    SECUIRTY_SUBSCRIPTION_ID=cab6c334-ae95-4a8d-8041-1127009a14bb
    BACKEND_STORAGE_ACCOUNT=cubetfstateprod
    WARNINGS="${WARNINGS}BE CAREFUL!!!\n\nYou are logged in to the battelle.us tenant.\n\n"
}
[[ $TENANT_ID == $DEVELOPMENT_TENANT_ID ]] && {
    BACKEND_STORAGE_ACCOUNT=cubetfstatedev2
}
[[ $TENANT_ID == $COMMERCIAL_PRODUCTION_TENANT_ID ]] && {
    BACKEND_STORAGE_ACCOUNT=cubetfstateprd
    SECUIRTY_SUBSCRIPTION_ID=1cb5093d-cd2f-4ef3-847b-621115aa2e54
    WARNINGS="${WARNINGS}\nBE CAREFUL!!!\n\nYou are logged in to the battelle.org tenant.\n\n"
}

echo -e $WARNINGS
cat <<EOM
=========================================================
SUBSCRIPTION: $workload($CURRENT_SUBSCRIPTION_ID)
WORKLOAD ENVIRONMENT: $name
DEPLOYMENT ID: $DEPLOYMENT_ID
TENANT ID: $TENANT_ID
PLATFORM SUBSCRIPTION: $PLATFORM_NAME($PLATFORM_SUBSCRIPTION_ID)
PLATFORM RESOURCE GROUP: $(recsel -t platform -e "id = '$platform'" -P name environments.rec)
SECUIRTY SUBSCRIPTION: $SECUIRTY_SUBSCRIPTION_ID
BACKEND STORAGE ACCOUNT: $BACKEND_STORAGE_ACCOUNT
CLOUD: $CLOUD_NAME
GRAPH URL: $GRAPH_URL
AZURE LOCATION: $LOCATION
AZURE ENVIRONMENT: $ENVIRONMENT
=========================================================

EOM

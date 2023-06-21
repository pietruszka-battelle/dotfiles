#!/usr/bin/env bash

default_domain() {
	az rest --url https://management.usgovcloudapi.net/tenants?api-version=2020-01-01 \
	--query "value[?tenantId == '$(az account show -s \
	"$(az account subscription list --only-show-errors \
	--query "[?displayName=='cube-platform'].subscriptionId" -o tsv)" \
	--query tenantId -o tsv)'].defaultDomain" -o tsv
}

source /home/pietruszka/.local/libexec/functions.sh

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	local name="$(default_domain)"
	local id="$(current-tenant-id)"
	local cloud="$(az cloud show --query "name" -o tsv)"
	setup   REST help:usage -- "Usage: cube tenant create -n <NAME> [options...] | -h"
	param	NAME	-n --name init:="$name"	-- "CUBE Tenant Name. Defaults to $name"
	param   ID -i --id init:="$id" -- "CUBE tenant id. Defaults to $id"
	param	CLOUD	-c --cloud	init:="$cloud"		-- "CLOUD that contains tenant. Defaults to $cloud"
	disp	:usage	-h --help
	msg -- '' 'Options:'
	param	ACCOUNT	-a --account init:="cubetfstateprod"	-- "CUBE State Storage Account Name (cubetfstateprod)"
}

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

# Add workload to recfile
echo -n "Addding tenant to configuration data store..."
cube-env-download $ACCOUNT
recins -t tenant -f name -v $NAME -f id -v $ID -f cloud -v $CLOUD environments.rec || die "Could not add tenant to recfile"
cube-env-upload $ACCOUNT
echo "done"
#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube workload status [options]" ''
	msg -- 'Options:'
	disp    :usage  -h --help
	param	WORKLOAD_NAME		--name -n	-- "CUBE WORKLOAD Name"
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

# Get workload recs from recfile
cube-env-download $ACCOUNT

rec_exists=no
[[ $(recsel -t workload -e "name = '$WORKLOAD_NAME'" environments.rec | wc -l) == 1 ]] && rec_exists=yes
echo "Record: $rec_exists"
divider

has_repo=no
gh repo view battellecube/$WORKLOAD_NAME 2>/dev/null >/dev/null && has_repo=yes
echo "Repo: $has_repo"
divider
workdir=$(mktemp -dq)
[[ $has_repo = "yes" ]] && {
    original_dir=$PWD
	cd $workdir
	gh repo clone battellecube/$WORKLOAD_NAME 2>/dev/null
	cd $WORKLOAD_NAME
	echo 'Unmerged Branches:'
	git branch --all --no-merged origin/main | sed 's,remotes/origin/,,'
	echo 'Open PRs'
	gh pr list
	cd $original_dir
}
divider

echo 'Environment Records'
recsel -t environment -e "workload = '$WORKLOAD_NAME'" environments.rec
divider

echo 'Azure environments'
for s in $(az account list --query [].id -o tsv 2>/dev/null)
do
	((i=i+1))
	(
	az group list --query "[?starts_with(name,'$WORKLOAD_NAME')].[id,name]" --subscription "$s" -o tsv | awk '{split($1, a, "/");print a[3], $2}') &
	pids[i]=$!
done
wait "${pids[@]}"
divider

echo 'Azure AD Groups'
az ad group list --query "[?starts_with(displayName,'cube-$WORKLOAD_NAME')].displayName" -o tsv
divider

[[ $has_repo = "yes" ]] && {
	echo 'CUBE Modules in use'
	cd $workdir/$WORKLOAD_NAME
	git submodule status
	cd -
	divider
}

echo "Linked Platforms/CUBEs"
az resource list --subscription $WORKLOAD_NAME --resource-type "Microsoft.Network/virtualNetworks" --query "[].id" -o tsv | awk -F/ '{print $3,$5,$9}' | while read sub rg vnet; do az network vnet peering list --subscription $sub -g $rg --vnet-name $vnet --query [].remoteVirtualNetwork.resourceGroup -o tsv; done|sort -u

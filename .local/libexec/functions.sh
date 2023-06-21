#!/usr/bin/env bash

# Use with log() like: log INFO "My msg"
declare -a LOG_LEVEL
LOG_LEVEL[CRITICAL]=0
LOG_LEVEL[ERROR]=1
LOG_LEVEL[WARN]=2
LOG_LEVEL[WARNING]=2
LOG_LEVEL[INFO]=3
LOG_LEVEL[DEBUG]=4

log()
{
	# ex: log ERROR "My err msg"
    # Log level defaults to 2 override by
	# ex: export SET_LOG_LEVEL=3
	LEVEL=$1
	# this doesn't work...so...yeah
	# if (( ${SET_LOG_LEVEL:-2} < ${LOG_LEVEL[$LEVEL]} )); then
	# 	return
	# fi
    MSG=$2
    CALL_STACK=$(
    local i=0
    while caller $i
    do
        ((i++))
    done
    )
    STACK_TRACE=$(
    while read frame
    do
        echo -e "  ...at line $frame"
    done <<<"$CALL_STACK"
    )
    echo -e "[$LEVEL] $MSG\n$STACK_TRACE" >&2
}

die() {
	log "ERROR" "$1" && exit 1
}

# Let's make sure we can only `source` this script, e.g., these should fail
#
#	./env-hook
#	bash env-hook
#	sh -c ./env-hook
#	cat env-hook |sh
# But these should work
#	. env-hook
#	source env-hook
[[ "${BASH_SOURCE}" != "${0}" ]] || die 'This script should only be `source`d. Exiting'

cube-env-deployment-id()
{
	echo "${workload}-${name}"
}

cube-env-sp-id(){
	az ad sp list --all --filter "displayname eq '$(cube-env-deployment-id)'" --query "[].id" -o tsv || die
}

cube-env-app-clientid(){
	# az ad app list --all --filter "displayname eq '$(cube-env-deployment-id)'" --query "[].appId" -o tsv || {
	az ad app list --all --query "[?displayName=='$(cube-env-deployment-id)'].appId" -o tsv || die
}

get-app-id(){
	local deployment_id=$1
	az ad app list --all --filter "displayname eq '${deployment_id}'" --query "[].id" -o tsv || die
}

delete-sp()
{
	local deployment_id=$1
	[ $(get-app-id $1) ] && (az ad app delete --id "$(get-app-id $1)" || die)
	
	rm -f .sp-environment.json
}

cube-env-get-graph-token()
{
	az account get-access-token --resource https://graph.microsoft.us --query accessToken -o tsv || die
}

cube-env-gh-branch-exists()
{
	# not sure why but this is not reliable
    TODO: fix this code, it is...strange
	[[ $(gh api \
	-H "Accept: application/vnd.github+json" \
	/repos/battellecube/${workload}/branches | \
	jq '[.[] | select(.name=="'${name}'")] | length') ]] || return 0

	die
}

cube-env-gh-branch-delete()
{
	# cube-env-gh-branch-exists is not reliable so commenting out for now 
	# may not be a big deal since response code of 422 is returned when 
	# deleting a branch that does not exists
	# cube-env-gh-branch-exists && return 0

	# tmp file to capture full response with response code on the last line
	local delete_response_code_file=$(mktemp)

	local delete_response=$(curl -s -w '\n%{http_code}'\
		-X DELETE\
		-H "Accept: application/vnd.github.v3+json"\
		-H "Authorization: token $(gh auth token)"\
		-H "Content-Type: application/json"\
		https://api.github.com/repos/battellecube/${workload}/git/refs/heads/${name} | tee $delete_response_code_file | head -n -1)

	# get the response code (last line from the tmp file)
	local delete_response_code=$(tail -n1 $delete_response_code_file)
	rm $delete_response_code_file

	[[ $delete_response_code -eq 422 || ($delete_response_code -ge 200 && $delete_response_code -le 299) ]] || die
}

cube-env-gh-branch-create()
{
	echo 'cube-env-gh-branch-create'
	# cube-env-gh-branch-exists is not reliable so commenting out for now 
	# may not be a big deal since response code of 422 is returned when 
	# creating a branch that already exists
	# cube-env-gh-branch-exists || return 0

	# tmp file to capture full response with response code on the last line
	local get_response_code_file=$(mktemp)

	# get the last commit sha on main
	local get_response=$(curl -s -w '\n%{http_code}'\
		-X GET \
		-H "Accept: application/vnd.github.v3+json" \
		-H "Authorization: token $(gh auth token)" \
		-H "Content-Type: application/json" \
		https://api.github.com/repos/battellecube/$workload/git/refs/heads/main | tee $get_response_code_file | head -n -1)

	local sha=$(echo $get_response | jq -r .object.sha)

	# get the response code (last line from the tmp file)
	local get_response_code=$(tail -n1 $get_response_code_file)

	# remove the tmp file
	rm $get_response_code_file

	[[ $get_response_code -ge 200 && $get_response_code -le 299 ]] || die

	# tmp file to capture full response with response code on the last line
	local post_response_code_file=$(mktemp)

	# create the branch
	local post_response=$(curl -s -w '\n%{http_code}'\
		-X POST\
		-H "Accept: application/vnd.github.v3+json"\
		-H "Authorization: token $(gh auth token)"\
		-H "Content-Type: application/json"\
		--data '{"ref":"refs/heads/'${name}'","sha":"'${sha}'"}'\
		https://api.github.com/repos/battellecube/${workload}/git/refs | tee $post_response_code_file | head -n -1)

	local post_response_code=$(tail -n1 $post_response_code_file)

	# remove the tmp file
	rm $post_response_code_file

	[[ $post_response_code -eq 422 || ($post_response_code -ge 200 && $post_response_code -le 299) ]] || die

}

cube-env-gh-environment-delete()
{
    #TODO: how do we know it really was deleted?
	local status_code=$(curl -s -w '%{http_code}' \
			-X DELETE \
			-H "Accept: application/vnd.github.v3+json" \
			-H "Authorization: token $(gh auth token)" \
			-H "Content-Type: application/json" \
			https://api.github.com/repos/battellecube/$workload/environments/$name)

	# what to really do with the status code?
	logger --priority local7.info "github delete environment http_code: ${status_code}"
}

cube-env-get-graph-id()
{
	az ad sp show  --id 00000003-0000-0000-c000-000000000000  --query "id"  -o tsv
}

cube-env-create-sp()
{
	local cit_security_subscription_id=$(cube-env-cit-security-subscription-id)
	local azure_dir_api_graph_id='00000003-0000-0000-c000-000000000000'
	local azure_dir_api_permission_id='19dbc75e-c2e2-444c-a770-ec69d8559fc7'

  	echo "...granting service principal 'Reader' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Reader"  \
			--scopes "/subscriptions/${cit_security_subscription_id}"  \
			--name "$(cube-env-deployment-id)" \
			--only-show-errors 1>/dev/null || die

	echo "...granting service principal 'Log Analytics Contributor' role for Log Analytics"
	az ad sp create-for-rbac  \
			--output none \
			--role "Log Analytics Contributor" \
			--scopes "/subscriptions/${cit_security_subscription_id}" \
			--name "$(cube-env-deployment-id)" \
			--only-show-errors 1>/dev/null || die

	echo "...granting service principal 'Owner' role for workload subscription"
	az ad sp create-for-rbac  \
			--output none \
			--role "Owner"  \
			--scopes "/subscriptions/$(cube-env-workload-subscription-id)" "/subscriptions/$(cube-env-platform-subscription-id)"  \
			--name "$(cube-env-deployment-id)" \
			--only-show-errors 1>/dev/null || die
	
	local sp_id=$(cube-env-sp-id)
	local app_role_id=$(az ad sp show  --id 00000003-0000-0000-c000-000000000000  --query "appRoles[?value=='Directory.ReadWrite.All'].id"  -o tsv)

	echo "...granting service principal Directory.ReadWrite.All permission and granting admin consent"
	az rest --method post \
		--headers '{"Authorization": "Bearer '"$(cube-env-get-graph-token)"'"}' \
		--url https://graph.microsoft.us/v1.0/servicePrincipals/$sp_id/appRoleAssignments \
		--body '{"principalId":"'"$sp_id"'","resourceId":"'"$(cube-env-get-graph-id)"'","appRoleId":"'"$app_role_id"'"}' \
		--only-show-errors 1>/dev/null || die
}

cube-env-current-subscription-id()
{
	az account show --query id -o tsv || die "cube-env-current-subscription-id failed"
}

current-tenant-id()
{
	az account show -s "$(cube-env-platform-subscription-id)" --query tenantId -o tsv || die
}

cube-workload-created()
{
	# return the first day of the month in which the workload was created
	# this is necessary for the budget consumption resource to have a start date in the correct format
	created_date=$(recsel -t workload -e "name = '$workload'" -P "created" environments.rec)
	date -d @$created_date '+%Y-%m-01T%H:%M:%SZ'
}

cube-workload-terraform-init()
{
	terraform init -upgrade \
		-backend-config=key=$(cube-env-deployment-id) \
		-backend-config=subscription_id=$(cube-env-platform-subscription-id) \
		-backend-config=environment=usgovernment \
		-backend-config=storage_account_name=${account} \
		--reconfigure || die
}

cube-workload-terraform-dev-vars()
{
	echo "$(cube-workload-terraform-vars) \
		-var=host_count=1"
}

cube-workload-terraform-vars()
{
	echo "-var=deployment_id=$(cube-env-deployment-id) \
		-var=subscription_id=$(cube-env-workload-subscription-id) \
		-var=platform_subscription_id=$(cube-env-platform-subscription-id) \
		-var=platform_deployment_id=$(recsel -t platform -e "id = '$platform'" -P name environments.rec) \
		-var=tenant_id=$(current-tenant-id) \
		-var=security_tenant_id=$(current-tenant-id) \
		-var=security_subscription_id=$(cube-env-cit-security-subscription-id) \
		-var=workload_name=${workload} \
		-var=address_space=${cidr} \
		-var=environment=usgovernment \
		-var=sha=$(git rev-parse HEAD) \
		-var=tool_version=$(cube -v) \
		-var=created=$(cube-workload-created) \
		-var=client_secret=$(cube-env-sp-client-secret) \
		-var=client_id=$(cube-env-sp-client-id)"
}

cube-env-az-start-hostpool-vms()
{
	local resource_group=$(cube-env-deployment-id)
	local endpoint="https://management.usgovcloudapi.net/"
	local subscription_id=$(cube-env-workload-subscription-id)
	local api_version="2021-09-03-preview"

	environment_name=$(az account show --query environmentName -o tsv)

	[ "$environment_name" == "AzureCloud" ] && {
		endpoint="https://management.azure.com/"
		api_version="2022-02-10-preview"
	}

	hostpool_vms=$(az rest --method get --url "$endpoint"subscriptions/$subscription_id/resourceGroups/$resource_group/providers/Microsoft.DesktopVirtualization/hostPools/$resource_group/sessionHosts?api-version=$api_version --query "value[].name" -o tsv)

	for i in $hostpool_vms;
	do
		vm_name=$(echo "$i" | awk -F "/" '{ print $2 }')
		echo "Starting $vm_name..."
		az vm start --name $vm_name --resource-group $resource_group --subscription $subscription_id --no-wait
	done

	return 0
}

cube-workload-terraform-destroy()
{
	cube-env-az-start-hostpool-vms || die "starting VMs failed"

	terraform destroy \
		$(cube-workload-terraform-vars) || die "terraform destroy failed"
}

# TODO should not have named environments hard coded in our tools
cube-workload-terraform-dev-apply()
{
	terraform apply \
		$(cube-workload-terraform-dev-vars) || die
}

cube-workload-terraform-apply()
{
	terraform apply \
		$(cube-workload-terraform-vars) || die
}

get-app-id(){
	local app_id_display_name=$1
	az ad app list --all --query "[?displayName=='${app_id_display_name}'].appId" -o tsv || die "error getting ${app_id_display_name} appId"
}

delete-client-secret()
{
	local deployment_id=$1
	local app_id=$(get-app-id $deployment_id)
	local key_id=$(az ad app list --all --query "[?displayName=='${deployment_id}'].passwordCredentials[]|[?displayName=='${deployment_id}-${USER}'].keyId" -o tsv)

	[ $key_id ] && (az ad app credential delete --id $app_id --key-id $key_id || die "error deleting key_id: ${key_id}")

	return 0
	
}

get-client-secret()
{
	local deployment_id=$1
	delete-client-secret $deployment_id

	local app_id=$(get-app-id $deployment_id)
	az ad app credential reset --id $app_id --display-name $deployment_id-$USER --append --only-show-errors --query "password" -o tsv || die "error reseting ${deployment_id}-${USER} app credential for appId: ${app_id}"
}

get-client-id()
{
	local deployment_id=$1
	az ad app list --all --query "[?displayName=='${deployment_id}'].appId" -o tsv
}

cube-env-workload-subscription-id()
{
	# this could/should be better
	if [ "$(az account subscription list --only-show-errors --query "[?displayName=='${sub}'] | length(@)")" == 1 ]; 
	then
		az account subscription list --only-show-errors --query "[?displayName=='${sub}'].subscriptionId" -o tsv || die
	else
		az account subscription list --only-show-errors --query "[?subscriptionId=='${sub}'].subscriptionId" -o tsv || die
	fi
}

cube-env-platform-subscription-id()
{
	az account subscription list --query "[?displayName=='cube-platform'].subscriptionId" -o tsv 2>/dev/null || die
}

cube-env-cit-security-subscription-id()
{
	local production_tenant_id=215220de-12d7-408e-b764-7e998342ac42
	local test_tenant_id=5f810341-3d89-4a77-9202-bf2cf933ec1a
	local commercial_production_tenant_id=2dd732a6-0413-473f-a1ce-68d1616444b6
	local current_tenant_id=$(current-tenant-id)

	local security_subscription_id=$(cube-env-platform-subscription-id)

	[[ $current_tenant_id == $production_tenant_id ]] && {
		security_subscription_id=cab6c334-ae95-4a8d-8041-1127009a14bb
	}

	[[ $current_tenant_id == $test_tenant_id ]] && {
		security_subscription_id=827fc093-c506-4119-a84f-45e88ee98db8
	}

	[[ $current_tenant_id == $commercial_production_tenant_id ]] && {
		security_subscription_id=1cb5093d-cd2f-4ef3-847b-621115aa2e54
	}

	echo $security_subscription_id

	# az account list  --refresh  --query "[?name == 'cit_security' && tenantId == '$(current-tenant-id)' && state == 'Enabled'] | [0].id"  -o tsv
}

cube-env-delete-record()
{
	local env_name=$1
	local workload_name=$2
	local account=$3

	cube-env-download $account

	matching_records=$(recsel -t environment -e "name = '$env_name' && workload = '$workload_name'" -p id environments.rec | wc -l)

	[[ $matching_records == 1 ]] || die "name '$env_name' for workload '$workload_name' does not exist in environment recfile"

	# recutil 1.8 has bug preventing TMPDIR from being on another partition--our /tmp is this way
	TMPDIR=. recdel -t environment -e "name = '$env_name' && workload = '$workload_name'" environments.rec

	cube-env-upload $account || die

	cube-env-unset-local
}

cube-env-make-record()
{
	local env_name=$1
	local workload_name=$2
	local cidr=$3
	local platform=$4
	local account=$5
	local sub=$6

	cube-env-download $account

	matching_records=$(recsel -t environment -e "name = '$env_name' && workload = '$workload_name'" -p id environments.rec | wc -l)

	[[ $matching_records == 0 ]] || \
		{
			echo -e "\n---------WARNING---------WARNING---------\n"
			echo -e "\nRecord ${env_name} for workload ${workload_name} already exists.  Do you want to update it? \n\nIf you're sure, press 'y' to continue.\n"
			read key
			[[ $key == "y" ]] || die

			logger -s --priority local7.error "cube-env-create: WARNING: updating record name '$env_name' for workload '$workload_name'."
			TMPDIR=. recdel -t environment -e "name = '$env_name' && workload = '$workload_name'" environments.rec
		}

	# recutil 1.8 has bug preventing TMPDIR from being on another partition--our /tmp is this way
	TMPDIR=. recins --verbose \
			-t environment \
			-f name -v $env_name \
			-f platform -v $platform \
			-f cidr -v $cidr \
			-f workload -v $workload_name \
			-f sub -v $sub \
			-f account -v $account \
			environments.rec || die "cube-env-make-record: recins command failed"

	cube-env-upload $account || die "cube-env-make-record: cube-env-upload failed"
}

cube-env-upload()
{
	local account=$1

	az storage azcopy blob upload \
			--account-name  $account \
			--container environments \
			--source environments.rec \
			--destination environments.rec \
			--subscription "$(cube-env-platform-subscription-id)" \
			--only-show-errors 1>/dev/null || die
}

cube-env-download()
{
	local account=$1
	local sub=$(cube-env-platform-subscription-id)
	az storage azcopy blob download \
			--account-name  $account \
			--container environments \
			--source environments.rec \
			--destination environments.rec \
			--subscription "$sub" \
			--only-show-errors 1>/dev/null  || die "cannot download recfile using $account and $sub"
}

cube-env-set-local()
{
	local env_name=$1
	local workload_name=$2

	[ -f ./environments.rec ] || die "cube-env-set-local: environments.rec file does not exits"
	. .cuberc || die ".cuberc file does not exist"

	matching_records=$(recsel -t environment -e "name = '$env_name' && workload = '$workload_name'" -p id environments.rec | wc -l)

	if [[ $matching_records == 0 ]]
	then
		log INFO "cube-env-set: ERROR: name '$env_name' for workload '$workload_name' does not exist in environment recfile"
		die "cube-env-set-local: no matching records found"
	fi
	
	if [ -f ".environment" ]; then
		eval $(awk -F ':' '{print "unset " $1}' < .environment) || die
		rm .environment
	fi

	recsel -t environment -e "name = '$env_name' && workload = '$workload_name'" environments.rec > .environment || die "cube-env-set-local: recsel failed"
	
	cube-env-eval || die "cube-env-set-local -> cube-env-eval failed"
	
	return 0
}

cube-platform-set-local()
{
	local platform_namename=cube-platform-$1

	local platform_tenant=$(current-tenant-id)

	[ -f ./environments.rec ] || die "cube-platform-set-local: environments.rec file does not exits"
	# should platform have a .quberc?
	# . .cuberc || die ".cuberc file does not exist"

	matching_records=$(recsel -t platform -e "name = '$platform_namename' && tenant = '$platform_tenant'" -p id environments.rec | wc -l)

	if [[ $matching_records == 0 ]]
	then
		log ERROR "cube-platfrom-set: ERROR: name '$platform_name'  does not exist in environment recfile"
		die "cube-platform-set-local: no matching records found"
	fi
	
	if [ -f ".platform" ]; then
		eval $(awk -F ':' '{print "unset " $1}' < .platform) || die
		rm .platform
	fi

	recsel -t platform -e "name = '$platform_namename' && tenant = '$platform_tenant'" environments.rec > .platform || die "cube-platform-set-local: recsel failed"
	
	cube-platform-eval || die "cube-platform-set-local -> cube-platform-eval failed"
	
	return 0
}

cube-env-eval()
{
	eval "$(awk -F ': ' '{print "export " $1"="$2}' < .environment)" || die "cube-env-eval failed"
}

cube-platform-eval()
{
	eval "$(awk -F ': ' '{print "export " $1"="$2}' < .platform)" || die "cube-platform-eval failed"
}

set-local-sp()
{
	local deployment_id=$1
	cat <<- EOF > .sp-environment.json
	{
		"AZURE_TENANT_ID":"$(current-tenant-id)",
		"AZURE_SUBSCRIPTION_ID":"${sub}",
		"AZURE_CLIENT_SECRET":"$(get-client-secret $deployment_id)",
		"AZURE_CLIENT_ID":"$(get-client-id $deployment_id)",
		"ARM_ENVIRONMENT":"usgovernment"
	}
	EOF
}

cube-env-sp-client-id()
{
	jq -r .AZURE_CLIENT_ID .sp-environment.json || die "cube-env-sp-client-id failed"
}

cube-env-sp-client-secret()
{
	jq -r .AZURE_CLIENT_SECRET .sp-environment.json || die "cube-env-sp-client-secret failed"
}

cube-env-validate()
{
	local repo_name=$(cube-env-repo-name)

	local warnings

	[ $workload != $repo_name ] && {
		warnings="${warnings}Your workload (${workload}) does not match your current directory (${repo_name}).\n\n"
	}

	local branch_name=$(cube-env-branch-name)

	[ $name != $branch_name ] && {
		warnings="${warnings}Your environment name ($name) does not match your current branch (${branch_name}).\n\n"
	}

	[ "$(echo $warnings | wc -w)" -gt 0 ] && {
		echo -e "\n------- warnings --------\n\n$warnings \n\nIf your are sure this is what you want, press 'y' to continue.\n"

		read key
    [[ $key == "y" ]] || die
	} || {
		return 0
	}
}

cube-env-unset-local()
{
	eval $(awk -F ':' '{print "unset " $1}' < .environment) || die
	rm .environment
}

cube-env-config-module()
{
	echo "Configuring module..."
}

cube-env-config-workload()
{
	echo "Configuring workload..."
	cube-cli-subscription-deployment-id

}

cube-env-branch-name()
{
	git rev-parse --abbrev-ref HEAD || die
}

cube-env-repo-name()
{
	basename "$(git rev-parse --show-toplevel || die)" || die
}

cube-env-sanitize-name()
{
	tr -d '-' || die
}

cube-env-version()
{
	local version_tag=$(git describe --tags)
	echo "${version_tag#v}"
}

cube-cli-subscription-deployment-id()
{
	echo "cube-cli-subscription-deployment-id"
	az account subscription list --query "[?displayName=='$(cube-env-repo-name)'].subscriptionId" -o tsv 2>/dev/null || die "failed to get subscription id!"
}

cube-terraform-platform-state-import()
{
	local addr=$1
	local id=$2

	terraform import \
		$(cube-platform-terraform-vars) \
		${addr} \
		${id} || die
}

cube-terraform-state-import()
{
	local addr=$1
	local id=$2

	terraform import \
		$(cube-workload-terraform-dev-vars) \
		${addr} \
		${id} || die
}

cube-terraform-state-rm()
{
	local addr=$1

	terraform state rm ${addr} || die
}

latest-release() {
	gh release list --repo battellecube/$1	`# get all the module info` \
		| awk '/Latest/{print $1}'			`# awk out the latest version`
}

divider() {
	local char="${1:--}"
	for i in $(seq 1 $(($(tput cols)-1)))
	do 
		echo -n $char
	done
	echo
}

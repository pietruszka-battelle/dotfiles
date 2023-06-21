#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube workload create -n <NAME> [options...] | -h"
	param	NAME	-n --name						-- "CUBE WORKLOAD Name"
	disp	:usage	-h --help
	msg -- '' 'Options:'
	param	ACCOUNT	-a --account init:="cubetfstateprod"	-- "CUBE State Storage Account Name (cubetfstateprod)"
	param	CORE	-c --core init:='default'				-- 'Use a named template for core module (default)'
	param	VDI 	-v --vdi init:='default'				-- 'Use a named template for vdi module (default)'
}

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh

# Add workload to recfile
echo -n "Addding workload to configuration data store..."
cube-env-download $ACCOUNT
CREATED=$(date '+%s')
recins -t workload -f name -v $NAME -f created -v $CREATED environments.rec || die "Could not add workload to recfile"
cube-env-upload $ACCOUNT
echo "done"

CIDR=$(for cidr in 10.237.{1..255}.0/24; do [[ $(recsel -t environment -e "cidr = '$cidr'" -p cidr environments.rec | tee | wc -l) == 0 ]] && echo $cidr ; done | head -n1)

# set up remote repo
/home/pietruszka/.local/libexec/cube-repo-create.sh -n $NAME --topic "cube workload" || die 'Could not create a repo'

# setup local repo
echo -n "Creating workload artifacts..."
repo_dir=$(mktemp -dq)
cd $repo_dir
gh repo clone battellecube/$NAME
cd $NAME
BRANCH_NAME="initial-setup"
git checkout -b $BRANCH_NAME

git submodule add --quiet git@github.com:battellecube/terraform-cube-core modules/terraform-cube-core|| die 'Could not add core module'
CORE_PATH="modules/terraform-cube-core/templates/$CORE.template"
[ -f $CORE_PATH ] && ln -s $CORE_PATH terraform-cube-core.tf
cd modules/terraform-cube-core
CUBE_CORE_VERSION=$(latest-release 'terraform-cube-core') || die "could not get latest core release tag"
git checkout --quiet $CUBE_CORE_VERSION || die "could not set core module to version $CUBE_CORE_VERSION"
cd - >/dev/null

git submodule add --quiet git@github.com:battellecube/terraform-cube-vdi modules/terraform-cube-vdi|| die 'Could not add VDI module'
VDI_PATH="modules/terraform-cube-vdi/templates/$VDI.template"
[ -f $VDI_PATH ] && ln -s $VDI_PATH terraform-cube-vdi.tf
cd modules/terraform-cube-vdi
CUBE_VDI_VERSION=$(latest-release 'terraform-cube-vdi') || die "could not get latest vdi release tag"
git checkout --quiet $CUBE_VDI_VERSION || die "could not set vdi module to version $CUBE_VDI_VERSION"
cd - >/dev/null

cat<<-HERE>README.md
	# $NAME

	This README should be captured in a template file under version control
	and added to the build as dist_templates_DATA or something cool like that
	HERE
cat <<-HERE>.cuberc
	#!/usr/bin/env bash

	# One of: WORKLOAD, MODULE
	CUBE_REPO_TYPE=WORKLOAD

	cube-env-create-hook()
	{
		return
	}

	cube-env-delete-hook()
	{
		return
	}
	HERE

cd $(git rev-parse --show-toplevel)
mkdir -p .github/workflows
cat <<-HERE>.github/workflows/deploy-environment.yml
	on:
	  push:
	    branches: ['main']
	jobs:
	  deploy-workload-environment:
	    runs-on: battellecube-ghec-1
	    environment: 'main'
	    env:
	      GH_TOKEN: \${{ github.token }}
	    steps:
	      - uses: actions/checkout@v3
	        with:
	          repository: battellecube/cube-env
	          ssh-key: \${{ secrets.SVCCUBECI_SSH_KEY }}
	          path: cube-env
	          ref: deb_repo
	      - run: sudo add-apt-repository -y ppa:rmescandon/yq
	      - run: |
	         wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
	         gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
	         echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
	         sudo apt update
	         sudo apt install terraform
	      - run: |
	         pwd
	         cd cube-env
	         ls
	         gpg --dearmor KEY.gpg
	         sudo mv KEY.gpg.gpg /usr/share/keyrings/cube-env-archive-keyring.gpg
	         sudo cp /usr/share/keyrings/cube-env-archive-keyring.gpg /etc/apt/trusted.gpg.d/
	         sudo cp cube-env.list /etc/apt/sources.list.d/
	         sudo apt update
	         sudo apt install cube-env
	      - uses: actions/checkout@v3
	        with:
	          ssh-key: \${{ secrets.SVCCUBECI_SSH_KEY }}
	          submodules: recursive
	      - run: |
	         az cloud set -n AzureUSGovernment
	         az login --allow-no-subscriptions --service-principal -u \${{ secrets.AZURE_CLIENT_ID }} -p \${{ secrets.AZURE_CLIENT_SECRET }} --tenant \${{ secrets.AZURE_TENANT_ID }}
	         az account set -s \${{ secrets.AZURE_SUBSCRIPTION_ID }}
	         az config set extension.use_dynamic_install=yes_without_prompt
	      - run: cube env set -n main -w $NAME
	      - run: |
	         terraform init -upgrade \
	           -backend-config=key=$NAME-main \
	           -backend-config=subscription_id=f3f3926c-bfc9-4986-b7d2-7bd45fae777a \
	           -backend-config=environment=usgovernment \
	           -backend-config=storage_account_name=cubetfstateprod \
	           -backend-config=client_id=\${{ secrets.AZURE_CLIENT_ID }} \
	           -backend-config=client_secret=\${{ secrets.AZURE_CLIENT_SECRET }} \
	           -backend-config=tenant_id=\${{ secrets.AZURE_TENANT_ID }}
	      - run: |
	         export ARM_SKIP_PROVIDER_REGISTRATION=true
	         terraform apply -auto-approve \
	           -var=deployment_id=$NAME-main \
	           -var=subscription_id=\${{ secrets.AZURE_SUBSCRIPTION_ID }} \
	           -var=platform_subscription_id=f3f3926c-bfc9-4986-b7d2-7bd45fae777a \
	           -var=platform_deployment_id=cube-platform-v0.6.0 \
	           -var=tenant_id=\${{ secrets.AZURE_TENANT_ID }} \
	           -var=security_tenant_id=\${{ secrets.AZURE_TENANT_ID }} \
	           -var=security_subscription_id=cab6c334-ae95-4a8d-8041-1127009a14bb \
	           -var=workload_name=${NAME} \
	           -var=address_space=$CIDR \
	           -var=environment=usgovernment \
	           -var=sha=\$(git rev-parse HEAD) \
	           -var=tool_version=$(cube -v) \
			   -var=created=$(date -d @$CREATED '+%Y-%m-01T%H:%M:%SZ') \
	           -var=client_secret=\${{ secrets.AZURE_CLIENT_SECRET }} \
	           -var=client_id=\${{ secrets.AZURE_CLIENT_ID }}
	HERE
git ignore-io terraform >> .gitignore
git ignore !terraform.tfvars environments.rec '.*environment*' *.ps1 >/dev/null
git add .
git commit -qm'initial commit'
git push --quiet -u origin $BRANCH_NAME || die 'could not publish artifacts to repository'
gh pr create --fill
echo "done"

# begin RBAC create stuff
current_tenant_id=$(az account show --query "tenantId" -o tsv) || die "Failed to get current tenantId"
current_domain=$(az ad signed-in-user show --query "userPrincipalName" --output tsv | awk -F'@' '{print $2}') || die "Failed to get current domain"
svccubeci_id=$(az ad user show --id svccubeci@$current_domain --query id --output tsv) || die "Failed to find id for svccubeci in $current_tenant_id"

az ad group create --only-show-errors --display-name "cube-$NAME-admins" --description "Admins group for $NAME AVD instance.  Users in this group will be Administrators on the session host" --mail-nickname "cube-$NAME-admins"
az ad group create --only-show-errors --display-name "cube-$NAME-managers" --description "Managers group for the $NAME workload.  Users in this group approve access to the $NAME workload users group" --mail-nickname "cube-$NAME-managers"

echo "---> Check for existence of group: cube-$NAME-users"
group_count=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "length(value)") || die "Failed to query for cube-$NAME-users group"

if [ $group_count -eq 1 ]
then
  echo "Group found, continuing..."
  group_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "value[].id" --output tsv) || die "Failed to get group id"
  group_creation=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "value[].createdDateTime" --output tsv) || die "Failed to get group creation time"
elif [ $group_count -eq 0 ]
then
  echo "Group not found, creating..."
  az rest --method post \
    --url 'https://graph.microsoft.us/beta/teams' \
    --body '{"template@odata.bind": "https://graph.microsoft.us/v1.0/teamsTemplates('\''standard'\'')", "displayName": '\"cube-$NAME-users\"', "description": "Group assignable to a role", "owners@odata.bind": ["https://graph.microsoft.com/v1.0/users('\'$svccubeci_id\'')"]}' || die "Failed to create Team from group"

  group_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "value[].id" --output tsv) || die "Failed to get group id"

  counter=0
  while [ $(az rest --method get --url  'https://graph.microsoft.us/v1.0/groups/'$group_id'/members' --query "length(value)") -eq 0 ]
  do
    counter=$((counter+1))
    if [ $counter -eq 5 ]
    then
      die "Member was never added to the group, can't continue"
    fi
    echo "...Waiting for member to be added, attempt number: $counter"
    sleep 2s
  done

  echo "Remove member..." #TODO: Figure out how to create the group without the owner being a member so this step can be removed
  az rest --method delete \
    --url 'https://graph.microsoft.us/v1.0/groups/'$group_id'/members/'$svccubeci_id'/$ref' || die "Failed to remove member"

  while [ -z "${group_id}" ]
  do
    echo "...wait for group creation to complete"
    sleep 5s
    group_id=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "value[].id" --output tsv) || die "Failed to get group id"
  done

  group_creation=$(az rest --method get --url "https://graph.microsoft.us/v1.0/groups?\$filter=displayName eq 'cube-$NAME-users'" --query "value[].createdDateTime" --output tsv) || die "Failed to get group creation time"
elif [ $group_count -gt 1 ]
then
  die "More than 1 group found with this name, exiting..."
fi

az rest --method patch --url 'https://graph.microsoft.us/v1.0/groups/'$group_id'' --body '{"securityEnabled": true}' || die "Failed to configure group as security enabled"

# end RBAC create stuff



/home/pietruszka/.local/libexec/cube-env-create.sh -n main -a $ACCOUNT -c $CIDR || die 'Could not create main environment'

cat <<HERE

$NAME has be created and is ready for deployment.  You can create a new
deployment environment with something like

cube env create --name <ENV_NAME>
HERE

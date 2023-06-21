#!/usr/bin/env bash


# shellcheck disable=SC2034
VERSION=0.15.5-1-g6c7f43c

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env [options]... [arguments]..." ''
	msg -- 'Options:'
	disp    :usage  -h --help
	disp    VERSION    --version

	msg -- '' 'Commands:'
	cmd storage -- "Manages CUBE environment storage"
	cmd create -- "Creates a CUBE environment"
	cmd delete -- "Deletes a CUBE environment"
	cmd list -- "List a CUBE environment"
	cmd set -- "Sets a CUBE environment"
	cmd apply -- "Terraform apply workload"
	cmd destroy -- "Terraform destory workload"
	cmd init -- "Terraform init workload"
	cmd grant -- "Grant users access to a workload"
	cmd ungrant -- "Remove users access to a workload"
	cmd state-import -- "Import resource into terraform state"
	cmd state-rm -- "Remove instance from terraform state "
	cmd rbac-create -- "Create rbac for an environment"
	cmd rbac-destroy -- "Destroy rbac for an environment"
	cmd rebuild-vm -- "Rebuild all VMs in environment"
	cmd migrate -- "Migrate to a new environment"
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

if [ $# -gt 0 ]; then
	cmd=$1
	shift
	case $cmd in
		storage)
			/home/pietruszka/.local/libexec/cube-env-storage.sh "$@"
			;;
		create)
			/home/pietruszka/.local/libexec/cube-env-create.sh "$@"
			;;
		delete)
			/home/pietruszka/.local/libexec/cube-env-delete.sh "$@"
			;;
		list)
			/home/pietruszka/.local/libexec/cube-env-list.sh "$@"
			;;
		set)
			/home/pietruszka/.local/libexec/cube-env-set.sh "$@"
			;;
		apply)
			/home/pietruszka/.local/libexec/cube-env-apply.sh "$@"
			;;
		destroy)
			/home/pietruszka/.local/libexec/cube-env-destroy.sh "$@"
			;;
		init)
			/home/pietruszka/.local/libexec/cube-env-init.sh "$@"
			;;
		grant)
			/home/pietruszka/.local/libexec/cube-env-grant.sh "$@"
			;;
		ungrant)
			/home/pietruszka/.local/libexec/cube-env-ungrant.sh "$@"
			;;
		state-import)
			/home/pietruszka/.local/libexec/cube-terraform-state-import.sh "$@"
			;;
		state-rm)
			/home/pietruszka/.local/libexec/cube-terraform-state-rm.sh "$@"
			;;
		rbac-create)
			/home/pietruszka/.local/libexec/cube-env-rbac-create.sh "$@"
			;;
		rbac-destroy)
			/home/pietruszka/.local/libexec/cube-env-rbac-destroy.sh "$@"
			;;
		rebuild-vm)
			/home/pietruszka/.local/libexec/cube-env-rebuild-vm.sh "$@"
			;;
		migrate)
			/home/pietruszka/.local/libexec/cube-env-migrate.sh "$@"
			;;
		--) # no subcommand, arguments only
	esac
fi




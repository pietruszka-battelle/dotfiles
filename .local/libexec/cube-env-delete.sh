#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube env delete [options]" ''
	msg -- 'Options:'
	disp		:usage			--help -h
	disp		VERSION			--version -v
	param		NAME			--name -n	-- "CUBE Environment Name"
	param		WORKLOAD --workload -w -- "CUBE Workload Name"
	param		ACCOUNT			--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
	flag		DELETE_BRANCH		--delete -d -- "Delete Git Branch"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh

echo "...setting up environment"
cube-env-download $ACCOUNT || die "cube-env-download failed"
cube-env-set-local $NAME $WORKLOAD || die "cube-env-set-local failed"

echo "...deleting service principal"
delete-sp $(cube-env-deployment-id)|| die "delete-sp"

echo "...deleting github environment"
cube-env-gh-environment-delete || die "cube-env-gh-environment-delete failed"

[ $DELETE_BRANCH ] && {
	echo "...deleting github branch"
	cube-env-gh-branch-delete || die "cube-env-gh-branch-delete failed"
}

echo "...running delete hook"
cube-env-delete-hook || die "cube-env-delete-hook failed"

cube workload module -r | while read l; do
	module=$(echo $l | awk -F= '{print $1}')
	cd modules/${module};
	[ -f ".cuberc" ] && {
		echo "...executing ${module} cube-env-delete-hook"
		source "$PWD/.cuberc"
		cube-env-delete-hook
	}
	cd - >/dev/null
done

echo "...deleting environment record"
cube-env-delete-record $NAME $WORKLOAD $ACCOUNT || die "cube-env-delete-record failed"

echo "...successfully deleted ${WORKLOAD}-${NAME} environment"

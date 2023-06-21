#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform delete [options] -n <name>" ''
	param	NAME		-n --name	-- "CUBE Platform Name.  The value provided will have cube-platform prepended to it and that will be the actual platform name.  So if v0.1.0 is provided then cube-platform-v0.1.0 will be that actual platform name"
	msg -- 'Options:'
	disp	:usage		-h --help
	disp	VERSION		-v --version
	param	ACCOUNT		-a --account init:="cubetfstateprod" -- "CUBE State Storage Account Name (defaults to cubetfstateprod)"
}

source /home/pietruszka/.local/libexec/functions.sh

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

delete-platform-record()
{
	local name="cube-platform-$1"
	local account=$2
	local tenant=$(current-tenant-id)

cat <<HERE
`divider`
Have made sure that platform ${name} has been properly cleaned up? (y/N)
`divider`
HERE
# TODO: consider a platform status command to recommend in order to make sure things are cleaned up

	read key
	[[ $key == "y" ]] || die "user aborted"
	
	# Remove workload from recfile
	cube-env-download $account || die "Could not download recfile"
	recdel -t platform -e "name = '$name' && tenant = '$tenant'" environments.rec || die "Could not remove platform $name from recfile"
	cube-env-upload $account || die "Could not upload recfile"

	eval $(awk -F ':' '{print "unset " $1}' < .platform) || die "eval of unset failed"
	rm -f .platform
}

[ -z ${NAME} ] && die "name value must be provided"

delete-sp "cube-platform-$NAME"

delete-platform-record $NAME $ACCOUNT

log INFO "...successfully deleted cube-platform-${NAME}"

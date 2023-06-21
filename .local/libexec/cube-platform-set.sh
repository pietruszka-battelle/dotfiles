#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube platform set [options]" ''
	msg -- 'Options:'
	disp	:usage		--help -h
	disp	VERSION		--version -v
	param	NAME		--name -n	-- "CUBE Platform Name"
	param	ACCOUNT		--account -a init:="cubetfstateprod" -- "CUBE State Storage Account Name"
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

source /home/pietruszka/.local/libexec/functions.sh

cube-env-download $ACCOUNT || die "cube-env-download failed"
cube-platform-set-local $NAME || die "cube-platform-set-local failed"
set-local-sp ${name}|| die "set-local-sp failed"





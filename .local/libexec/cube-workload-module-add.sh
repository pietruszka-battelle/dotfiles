#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage							-- "Usage: cube workload add [options]" ''
	msg												-- 'Options:'
	disp    :usage		-h --help
	param	MODULE_NAME	-n --name init:@unset	-- 'The name of the module'
	param	TEMPLATE	-t --template init:='default'	-- 'Use a named template'
}
# @end

source /home/pietruszka/.local/libexec/functions.sh

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

[ -f .cuberc ] || die "You are not in a workload repo"

[ ${MODULE_NAME+set} ] || die "You must provide a MODULE_NAME [-n | --name]"

[[ "$(git branch --show-current)" == "main" ]] && die 'Do not add modules to the main branch, try something like git checkout -b my-new-branch'

git submodule add git@github.com:battellecube/$MODULE_NAME modules/$MODULE_NAME

TEMPLATE_PATH="modules/$MODULE_NAME/templates/$TEMPLATE.template"
[ -f $TEMPLATE_PATH ] && ln -s $TEMPLATE_PATH $MODULE_NAME.tf

#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage			-- "Usage: cube workload module list [options]" ''
	msg								-- 'Options:'
	disp    :usage  -h --help
	flag	FLAG_R	-r init:@unset	-- 'Display a tree of nested modules'
}
# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"
source /home/pietruszka/.local/libexec/functions.sh
[ -f .cuberc ] || die "You are not in a workload repo"
git submodule --quiet update --init --recursive
if [ ${FLAG_R+x} ]; then
	tree -I 'docs|disabled' -d modules/
else
	git submodule status
fi

#!/usr/bin/env bash


# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	setup   REST help:usage -- "Usage: cube repo mirror [options]..." ''
	msg -- 'Options:'
	disp    :usage			--help -h
}

# @end

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

gh repo list battellecube --limit 1000 --topic cube --json name --jq '.[].name' | sort

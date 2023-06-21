#!/usr/bin/env bash

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	array() { param ":append_array $@"; }
	msg -- 'Create repository in GitHub and runs all configuration' ''
	setup   REST help:usage -- "Usage: cube repo create [options]..." ''
	msg -- 'Options:'
	disp    :usage		--help -h
	param	REPO_NAME	--repo-name -n -- 'Name of the GitHub repository'
    option	ORG			--organization -o init:=battellecube -- 'GitHub organization name'
	flag	DEBUG		--debug -- 'Turn on debug out for this command'
}
# @end

source /home/pietruszka/.local/libexec/functions.sh

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

[ -z ${REPO_NAME} ] && die 'You need a REPO_NAME'

if [ $DEBUG ]
then
	cat <<-HERE
	REPO_NAME: $REPO_NAME
	GHAE: $GHAE
	ORG: $ORG
	TYPE: $TYPE
	PROTECT: $PROTECT
	TOPICS: $(IFS=', '; echo "${TOPIC[*]}") (${#TOPIC[@]})
	HERE
fi

gh repo archive $ORG/$REPO_NAME --yes || die "Don't think repo [$REPO_NAME] was archived :/"

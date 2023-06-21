#!/usr/bin/env bash


# shellcheck disable=SC2034
WORKLOAD_TYPES='workload | platform | module' 

# shellcheck disable=SC1083
# @getoptions
parser_definition() {
	array() { param ":append_array $@"; }
	msg -- 'Create repository in GitHub and runs all configuration' ''
	setup   REST help:usage -- "Usage: cube repo create [options]..." ''
	msg -- 'Options:'
	disp    :usage		--help -h
	param	REPO_NAME	--repo-name -n -- 'Name of the GitHub repository'
	flag	GHAE		--{no-}ghae -g +g -- 'Use GHAE instead of GitHub.com'
	option	ORG			--organization -o init:=battellecube -- 'GitHub organization name'
	flag	PROTECT		--{no-}protection -p +p init:=1 -- 'Set GitHub repo protections'
	array	TOPIC		--topic init:'TOPICS=()' var:TOPIC -- 'Add custom topic to repo.  Multiple `--topic`s allowed'
	flag	DEBUG		--debug -- 'Turn on debug out for this command'
	msg -- 'Examples:' ''
	msg -- '  Adding topics:'
	msg -- '    cube repo create --topic TOPIC1'
	msg -- '    cube repo create --topic "TOPIC1 TOPIC2"'
	msg -- '    cube repo create --topic=TOPIC1,TOPIC2'
	msg -- '    cube repo create --topic={TOPIC1,TOPIC2}'
}
# @end

source /home/pietruszka/.local/libexec/functions.sh

append_array() {
	IFS+=,
	eval "$1+=(\`echo \"\$OPTARG\"\`)"
}

eval "$(/home/pietruszka/.local/bin/getoptions parser_definition - "$0") exit 1"

[ -z ${REPO_NAME} ] && die 'You need a REPO_NAME'
[[ "$REPO_NAME" =~ ^- ]] && die 'REPO_NAME cannot start with a dash'

if [ $DEBUG ]
then
	cat <<-HERE
	REPO_NAME: $REPO_NAME
	GHAE: $GHAE
	ORG: $ORG
	PROTECT: $PROTECT
	TOPICS: $(IFS=', '; echo "${TOPIC[*]}") (${#TOPIC[@]})
	HERE
fi

# create remote repo
log INFO 'Publishing artifacts...'
gh repo create battellecube/$REPO_NAME --private --team cube-owners --add-readme || die

# set branch protections
if [ $PROTECT ]
then
	log INFO "setting branch protections"
	protection_response=$(curl -s -X PUT -H 'Accept: application/vnd.github+json' -H "Authorization: Bearer $(gh auth token)" https://api.github.com/repos/battellecube/$REPO_NAME/branches/main/protection -d '{"required_status_checks":{"strict":true,"contexts":[]},"enforce_admins":true,"required_pull_request_reviews":{"dismissal_restrictions":{"users":[],"teams":[]},"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1,"require_last_push_approval":true,"bypass_pull_request_allowances":{"users":[],"teams":[]}},"restrictions":{"users":[],"teams":[],"apps":[]},"required_linear_history":true,"allow_force_pushes":false,"allow_deletions":true,"block_creations":true,"required_conversation_resolution":true,"lock_branch":false,"allow_fork_syncing":true}' || die "We aren't protected!")
	log INFO "done"
fi

# add topics
topics=$(for topic in ${TOPIC[@]}
	do
		echo -n " --add-topic $topic"
	done
)

[ "$topics" ] && gh repo edit battellecube/$REPO_NAME $topics

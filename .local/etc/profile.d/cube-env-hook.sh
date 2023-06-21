#!/usr/bin/env bash

# Let's make sure we can only `source` this script, e.g., these should fail
#
#	./env-hook
#	bash env-hook
#	sh -c ./env-hook
#	cat env-hook |sh
# But these should work
#	. env-hook
#	source env-hook
[[ "${BASH_SOURCE}" != "${0}" ]] \
	&& echo 'Hooking into the CUBE' \
	|| \
	{ 
		echo 'This script should only be `source`d. Exiting' >&2
		exit 1 
	}

# Not the right place for this but don't want to forget it :)
# export CUBE_PERSONAL_ACCESS_TOKEN=$(yq e '."github.com".oauth_token' ~/.config/gh/hosts.yml)

cd()
{
	builtin cd "$@" || return 1
	cube-env-config
}

pushd()
{
	builtin pushd "$@" || return 1
	cube-env-config
}

popd()
{
	builtin popd "$@" || return 1
	cube-env-config
}

cube-env-config()
{
	if [[ -f $PWD/.cuberc ]]
	then
		echo "Changing from \"$OLDPWD\" to \"$PWD\""
		source $PWD/.cuberc

		case $CUBE_REPO_TYPE in
			WORKLOAD)
				echo "Configuring workload"
				;;
			MODULE)
				echo "Configuring module"
				;;
			*)
				echo "What?"
				;;
		esac
	fi
}


#! /bin/bash

REPO=$(git rev-parse --show-toplevel)

source /home/pietruszka/.local/libexec/functions.sh

cat <<HERE

`divider`
Watching the .github/workflows directory for changes.  Only changes to this
directory will push changes and trigger the GH Action workflow.

NOTE: This is done by amending and force pushing the last commit!!  You may
want to make a commit specifically for workflow changes, e.g.,

	git commit -m'Debugging GH Actions Sucks'

`divider`

HERE

while true; do
	inotifywait -q --recursive --exclude='.*.swp' -e modify $REPO/.github/workflows |
    while read dir op file
    do
		git commit -a --amend --no-edit
		git push -f
		for i in $(seq 1 $(tput cols)); do echo -n '-'; done
    done
done

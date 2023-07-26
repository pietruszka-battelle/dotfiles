#!/bin/bash

repo_name=$1
branch_name="main"

get_branch_protection () {
	gh api -X GET /repos/battellecube/$repo_name/branches/$branch_name/protection
}

delete_branch_protection () {
	gh api \
		--method DELETE \
		-H "Accept: application/vnd.github+json" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		/repos/battellecube/$repo_name/branches/$branch_name/protection
}

read -p "Are you sure you want to delete branch protections for $branch_name on $repo_name? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	delete_branch_protection
fi

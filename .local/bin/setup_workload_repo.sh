#!/bin/bash


WL=$1

cd ~ || exit
CLONEREPONAME="battellecube/$WL"
gh repo clone "$CLONEREPONAME"
cd ~/"$WL" || exit

git merge origin/initial-setup
git push -f
git submodule update --init --recursive


#!/bin/bash

WL=$1
cd ~ || exit
gh repo clone battellecube/$WL
cd $WL || exit 
git submodule update --init --recursive
cube env set -w $WL -n main
cube env init
cube env destroy
cube env delete -w $WL -n main
cube workload rbac delete -n $WL
cube workload delete -n $WL
cd ~ || exit
rm -rf $WL

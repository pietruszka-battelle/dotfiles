#!/bin/bash

$command='echo $env:OneDrive'
$onedrivepath=$(powershell.exe -Command $command) | exit 1
echo $onedrivepath


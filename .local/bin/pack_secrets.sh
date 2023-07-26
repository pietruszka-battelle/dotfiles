#!/bin/bash
dir=$(powershell.exe -c "\$env:OneDrive" | awk '{sub(/\r/,""); print $0 "\\Documents\\secrets.tar"}')
drive_dir=$(wslpath -u "$dir")
cd ~
tar -cf secrets.tar .ssh/ .gnupg/ .config/gh/hosts.yml
mv secrets.tar "$drive_dir"

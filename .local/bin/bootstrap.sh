#!/usr/bin/env bash

set -e

install-common-packages()
{
	sudo apt update
	sudo apt dist-upgrade -y
	sudo apt install -y powerline vim-nox build-essential gnupg curl tmux git{,-lfs} silversearcher-ag etckeeper xdg-utils wslu software-properties-common python3-pip cmake ripgrep
	sudo apt install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
	git lfs install
}

install-nvim() {
	cd ~
	git clone https://github.com/neovim/neovim.git
	git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	cd ~/neovim
	make CMAKE_BUILD_TYPE=RelWithDebInfo
	sudo make install
	cd ~
}

install-azure-cli() 
{
	type -p curl >/dev/null || install-common-packages
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
	az cloud set --name AzureUSGovernment
	az config set extension.use_dynamic_install=yes_without_prompt
}

install-terraform-cli()
{
	type -p wget gpg >/dev/null || install-common-packages
	wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/hashicorp-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/terraform-cli.list > /dev/null
	sudo apt-get update && sudo apt-get install terraform -y
}

install-yq()
{
	type -p add-apt-repository >/dev/null || install-common-packages
	sudo add-apt-repository -y ppa:rmescandon/yq
	sudo apt update
	sudo apt install yq -y
}

install-github-cli()
{
	type -p curl >/dev/null || install-common-packages
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update && sudo apt install gh -y
}

install-cube-cli()
{
	type -p gh >/dev/null || install-github-cli
	type -p gpg >/dev/null || install-common-packages
	gh api -H 'Accept: application/vnd.github.raw' /repos/battellecube/cube-env/contents/KEY.gpg?ref=deb_repo | gpg --dearmor | sudo dd of=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/cubeenvcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee /etc/apt/sources.list.d/cube-env.list > /dev/null
	echo "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/cubeenvcli-archive-keyring.gpg] https://battellecube.github.io/cube-env ./" | sudo tee -a /etc/apt/sources.list.d/cube-env.list > /dev/null
	sudo apt update
	sudo apt install -y cube-env
	sudo apt build-dep -y cube-env
}

install-nvm()
{
	type -p curl >/dev/null || install-common-packages
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	nvm install --lts
	nvm install-latest-npm
}


install-common-packages
install-yq
install-nvim
install-github-cli
install-terraform-cli
install-azure-cli
install-nvm
install-cube-cli

# setup-windows-terminal
# echo -e "\n\nYou'll wants these fonts\n\thttps://github.com/powerline/fonts"

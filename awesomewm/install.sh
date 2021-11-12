#!/usr/bin/bash

source ./config

CP='sudo cp -rfv'

BOLD='\033[1m'
NORMAL='\033[0m'

if [ "$EUID" = 0 ]; then
    echo 'This script cannot be run as root'
    exit 1
fi

################
### Packages ###
################
paru --noconfirm --needed -Syu "${packages[*]}"

############
### Xorg ###
############
echo -e '#!/bin/sh\n\nexec awesome' > "$HOME"/.xinitrc

echo 'enter sudo passwd to copy xorg config'
$CP ../etc/X11 /etc

# TODO : ssh config
################
### Dotfiles ###
################
config="git --git-dir $HOME/.dotfiles --work-tree $HOME"

echo -en ":: Do you want to clone public repo? [Y/n] $NORMAL"
read -r ans
case "${ans,,}" in
    '' | 'y' | 'yes')
        git clone --bare https://github.com/AustralEpitech/dotfiles.git "$HOME"/.dotfiles
        #git clone --bare git@github.com:AustralEpitech/dotfiles.git $HOME/.dotfiles
        $config checkout main "$HOME"
        $config submodule init
        $config submodule update
        $config config status.showUntrackedFiles no
        ;;
esac

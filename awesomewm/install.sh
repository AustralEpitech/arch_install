#!/usr/bin/bash

source ./config

CP='sudo cp -rfv'

BOLD='\033[1m'
NORMAL='\033[0m'

review_config() {
    less ./config
    echo -en "$BOLD:: Press enter to start$NORMAL"
    read -r
}

install_packages() {
    paru --noconfirm --needed -Syu "${packages[*]}"
}

configure_xorg() {
    echo -e '#!/bin/sh\n\nexec awesome' > "$HOME"/.xinitrc

    echo 'enter sudo passwd to copy xorg config'
    $CP ../etc/X11 /etc
}

clone_config() {
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
}

# TODO : ssh config

main() {
    if [ "$EUID" = 0 ]; then
        echo 'This script cannot be run as root'
        exit 1
    fi

    set -e
    review_config
    install_packages
    configure_xorg
    clone_config
}

main

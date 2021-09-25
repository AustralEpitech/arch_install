#!/usr/bin/bash

source ./config

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

set_xinit() {
    echo -e '#!/bin/sh\n\nexec awesome' > "$HOME"/.xinitrc
}

clone_config() {
    config="git --git-dir $HOME/.dotfiles --work-tree $HOME"

    echo -e "${BOLD}TODO: add github GPG key and clone dotfiles: git clone --bare git@github.com:AustralEpitech/dotfiles.git $HOME/.dotfiles"
    echo -en ":: Do you want to clone public repo? [Y/n] $NORMAL"
    read -r ans
    case "${ans,,}" in
        '' | 'y' | 'yes')
            git clone --bare https://github.com/AustralEpitech/dotfiles.git "$HOME"/.dotfiles
            $config checkout main "$HOME"
            $config submodule init
            $config submodule update
            $config config status.showUntrackedFiles no
            ;;
    esac
}

# TODO : ssh config, xorg cp

main() {
    if [ "$EUID" = 0 ]; then
        echo 'This script cannot be run as root'
        exit 1
    fi

    set -e
    review_config
    install_packages
    set_xinit
    clone_config
}

main

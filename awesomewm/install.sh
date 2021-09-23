#!/usr/bin/bash

source ./config

review_config() {
    less ./config
    echo -en "$BOLD:: Press enter to start$NORMAL"
    read -r
}

install_packages() {
    paru -Syu "$packages[*]"
}

set_xinit() {
    echo -e '#!/bin/sh\n\nexec awesome' > "$HOME"/.xinitrc
}

clone_config() {
   git clone --bare --recurse-submodules git@github.com:AustralEpitech/dotfiles.git $HOME/.dotfiles 
}

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

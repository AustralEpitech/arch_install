#!/usr/bin/bash

source ./config

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
    set -e
    install_packages
    set_xinit
    clone_config
}

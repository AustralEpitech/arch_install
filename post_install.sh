#!/bin/bash

AUR_PACKAGES=(
    brave-bin
    nerd-fonts-meslo
    shellcheck-bin
)

TECH_PACKAGES=(
    csfml
    criterion
    docker
    emacs
    gcovr
    gdb
    valgrind
)

git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
cd /tmp/paru-bin
makepkg -si --noconfirm

paru --noconfirm --needed -S ${AUR_PACKAGES[*]}
paru --needed -S ${TECH_PACKAGES[*]}

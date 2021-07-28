#!/bin/bash

PARU='paru --needed -S'

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

$PARU --noconfirm "${AUR_PACKAGES[@]}"
$PARU "${TECH_PACKAGES[@]}"

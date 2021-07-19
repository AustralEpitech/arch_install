#!/bin/bash

##### TODO #####
# Terminal fonts
# Refactor into function ?

CONFIG_DIR="config/"

BOLD="\033[1m"
NORMAL="\033[0m"
CP="cp -f"

PACKAGES=(
    brave-bin
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

set -e

git clone https://aur.archlinux.org/paru-bin.git /tmp
cd /tmp/paru-bin
makepkg -si --noconfirm

paru -Syyu --noconfirm --needed "${PACKAGES[@]}"
paru -S --needed "${TECH_PACKAGES[@]}"

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

"$CP" "$CONFIG_DIR/.zshrc" ~

echo -e "\n\n    ${BOLD}DONE${NORMAL}\n"

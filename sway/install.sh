#!/usr/bin/bash

source ./config

NORMAL="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"

if [ "$EUID" = 0 ]; then
    echo "This script cannot be run as root"
    exit 1
fi

################
### Packages ###
################
paru --noconfirm --needed -Syu "${packages[@]}"

###########
### END ###
###########
echo -e "${BOLD}${GREEN}DONE.${NORMAL}"

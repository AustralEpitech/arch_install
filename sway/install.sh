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

#TODO: SSH config

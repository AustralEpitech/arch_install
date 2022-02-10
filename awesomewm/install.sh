#!/usr/bin/bash

set -e
source ./config

CP="sudo cp -frv"

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
if lspci | grep "Radeon"; then
    packages=(${packages[@]} xf86-video-amdgpu)
fi
paru --needed -Syu "${packages[@]}"

############
### Xorg ###
############
echo -e "#!/bin/sh\n\nexec awesome" > "$HOME"/.xinitrc

echo "${BOLD}Enter sudo passwd to copy xorg config${NORMAL}"
$CP ../etc/X11 /etc

###########
### END ###
###########
echo -e "${BOLD}${GREEN}DONE.${NORMAL}"

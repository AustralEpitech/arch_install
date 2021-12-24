#!/usr/bin/bash

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
paru --noconfirm --needed -Syu "${packages[@]}"

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

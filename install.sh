#!/usr/bin/bash
set -e

set -a
NORMAL="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"

WORKDIR="$(dirname "$0")"
SRC="$(cd "$WORKDIR/src" && pwd)"
CONFIG="$(cd "$WORKDIR/config" && pwd)"
set +a

bash "$SRC/0-preinstall.sh" &> 0-preinstall.log
arch-chroot /mnt "$SRC/1-setup.sh" > 1-setup.log
[ "$GUI" ] && arch-chroot /mnt runuser -u "$USERNAME" -c "$SRC/2-user.sh" &> 2-user.log
arch-chroot /mnt "$SRC/3-postsetup.sh" > 3-postsetup.log

echo "${BOLD}${GREEN}Installation finished. You may now reboot.${NORMAL}"

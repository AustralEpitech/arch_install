#!/usr/bin/bash

set -e
source ./config

NORMAL="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"

CP="cp -fv"
SED="sed -i"
SU="su $username -c"
PACMAN="pacman --needed -Syu"

#############
### Clock ###
#############
ln -sf /usr/share/zoneinfo/"$tz" /etc/localtime
hwclock --systohc
timedatectl set-ntp true

##############
### Locale ###
##############
for i in "${locales[@]}"; do
    $SED "s/^#$i/$i/" /etc/locale.gen
done
locale-gen
echo "LANG=$lang" > /etc/locale.conf

################
### Hostname ###
################
echo "$hostname" > /etc/hostname

################
### Packages ###
################
$CP "etc/pacman.conf" /etc/
${PACMAN} "${pkg[@]}"

#############
### Users ###
#############
zsh_path="$(which zsh)"
echo "root:$root_passwd" | chpasswd

if [ "$zsh_path" ]; then
    useradd -mG wheel "$username" -s "$zsh_path"
    $SU 'yes | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
else
    useradd -mG wheel "$username"
fi

echo "$username:$user_passwd" | chpasswd

$SED "s/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/" /etc/sudoers

###########
### AUR ###
###########
mv /etc/sudoers /etc/sudoers.bak
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers

$SU "git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && cd /tmp/paru-bin && makepkg -si --noconfirm"

[ "$tech_install" ] && $SU "paru --needed -S ${tech_pkg[*]}"

mv /etc/sudoers.bak /etc/sudoers

##################
### Bootloader ###
##################
case "$gpu" in
    *AuthenticAMD*)
        $PACMAN amd-ucode
        ;;
    *GenuineIntel*)
        $PACMAN intel-ucode
        ;;
esac

grub-install --target=x86_64-efi --efi-directory="$esp" --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

################
### Services ###
################
systemctl enable NetworkManager
systemctl enable tlp

###########
### GPU ###
###########
case "$gpu" in
    *NVIDIA*)
        $PACMAN nvidia{,-settings}
        mkdir /etc/pacman.d/hooks -p && $CP etc/pacman.d/hooks/nvidia.hook /etc/pacman.d/hooks
        $SED "s/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm/" /etc/mkinitcpio.conf
        ;;
    *Radeon*)
        $SED "s/^MODULES=(/MODULES=(amdgpu/" /etc/mkinitcpio.conf
        ;;
esac

#########################
### Rebuild initramfs ###
#########################
mkinitcpio -P

###########
### END ###
###########
echo -e "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot${NORMAL}"

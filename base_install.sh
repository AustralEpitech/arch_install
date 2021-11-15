#!/usr/bin/bash

source ./config

BOLD='\033[1m'
GREEN='\033[32m'
NORMAL='\033[0m'

CP='cp -fv'
SED='sed -i'
SU="su $username -c"
PACMAN='pacman --noconfirm --needed -Syu'

boot_entries='/boot/loader/entries'

#############
### Clock ###
#############
ln -sf /usr/share/zoneinfo/"$tz" /etc/localtime
hwclock --systohc
timedatectl set-ntp true

##############
### Locale ###
##############
for i in ${locales[*]}; do
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

if [ -n "$zsh_path" ]; then
    useradd -mG wheel "$username" -s "$zsh_path"
    $SU 'yes yes | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
else
    useradd -mG wheel "$username"
fi

echo "$username:$user_passwd" | chpasswd

$SED 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers

###########
### AUR ###
###########
mv /etc/sudoers /etc/sudoers.bak
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers

$SU 'git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && cd /tmp/paru-bin && makepkg -si --noconfirm'

[ "$tech_install" ] && $SU "paru --no-confirm --needed -S ${tech_pkg[*]}"

mv /etc/sudoers.bak /etc/sudoers

##################
### Bootloader ###
##################
bootctl install
mkdir -p /etc/pacman.d/hooks && $CP etc/pacman.d/hooks/100-systemd-boot.hook /etc/pacman.d/hooks/
echo -e "$btl_opt" > /boot/loader/loader.conf
echo -e 'title   Arch Linux\nlinux   /vmlinuz-linux\ninitrd  /initramfs-linux.img' > "$boot_entries"/arch.conf

if lscpu | grep -q GenuineIntel; then
    $PACMAN intel-ucode
    echo "initrd  /intel-ucode.img" >> "$boot_entries"/arch.conf
elif lscpu | grep -q AuthenticAMD; then
    $PACMAN amd-ucode
    echo "initrd  /amd-ucode.img" >> "$boot_entries"/arch.conf
fi

echo "options root=$(lsblk -p --list | awk '$7 == "/" {print $1}')" >> "$boot_entries"/arch.conf

$CP "$boot_entries"/arch.conf "$boot_entries"/arch-fallback.conf
$SED 's/Arch Linux$/Arch Linux (fallback initramfs)/; s/initramfs-linux.img$/initramfs-linux-fallback.img/' "$boot_entries"/arch-fallback.conf

###############
### Network ###
###############
$PACMAN networkmanager
systemctl enable NetworkManager

###########
### GPU ###
###########
if lspci | grep "NVIDIA"; then
    $PACMAN nvidia{,-settings}
    mkdir /etc/pacman.d/hooks -p && $CP etc/pacman.d/hooks/nvidia.hook /etc/pacman.d/hooks
    $SED "s/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm/" /etc/mkinitcpio.conf
    nvidia-xconfig
elif lspci | grep "Radeon"; then
    $SED "s/^MODULES=(/MODULES=(amdgpu/" /etc/mkinitcpio.conf
fi

###########
### END ###
###########
echo -e "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot${NORMAL}"

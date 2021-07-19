#!/bin/bash

##### TODO #####
# Cp ISO boot config
# Refactor into function?

USERNAME="ange"
MYHOSTNAME="${USERNAME^^}-LAPTOP"
TIMEZONE="Europe/Paris"
CONFIG_DIR="config/"

CP="cp -f"
PACMAN="pacman --noconfirm --needed"

PACKAGES=(
    alacritty
    base-devel clang cmake python{,-pip}
    code
    discord
    gimp okular obs-studio
    git
    gparted ntfs-3g
    htop
    intel-ucode nvidia{,-settings}
    linux-headers
    lutris steam wine-{gecko,mono,staging} winetricks
    man-{db,pages} texinfo
    neofetch
    networkmanager
    noto-fonts{,-cjk,-emoji} ttf-dejavu
    openssh
    pipewire{,-alsa,-pulse}
    tree
    unrar
    vim
    wget
    xclip
    xorg{,-xinit}
    zsh
)

if [ ! -d /sys/firmware/efi/efivars ]; then
    echo "ERROR: System must be UEFI"
    exit 1
fi

if [ ! "$(ping -c1 archlinux.org)" ]; then
    echo 'ERROR; Check your internet connexion'
    exit 1
fi

set -e

"$CP" -r "$CONFIG_DIR"/etc /etc

"$PACMAN" -Syyu reflector
systemctl start reflector

"$PACMAN" -S "${PACKAGES[@]}"

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc
timedatectl set-ntp true

sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g; s/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$MYHOSTNAME" > /etc/hostname
echo \
"127.0.0.1  localhost
::1         localhost
127.0.1.1   $MYHOSTNAME.localdomain $MYHOSTNAME" >> /etc/hosts

bootctl install

echo -e "\nroot passwd"
passwd

useradd -m -G wheel $USERNAME

echo "$USERNAME passwd"
passwd $USERNAME

sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers

"$CP" -r "$CONFIG_DIR"/boot /boot/

systemctl enable NetworkManager
nvidia-xconfig

sed -i "s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf

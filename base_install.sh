#!/bin/bash

# User variables
USERNAME='ange'
MYHOSTNAME="${USERNAME^^}-LAPTOP"
TIMEZONE='Europe/Paris'
CONFIG_DIR='config/'

# Colors
BOLD='\033[1m'
GREEN='\033[32m'
NORMAL='\033[0m'

ENTRIES='/boot/loader/entries/'
ROOT_DISK="$(lsblk -p --list | awk '$7 == "/" {print $1}')"
CP='cp -f'
SU="su $USERNAME -c"
SED='sed -i'
PAC_OPT='--noconfirm --needed -S'

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

ask() {
    while true; do
        read -p "${BOLD}:: $1 [Y/n] ${NORMAL}" ANS
        case "${ANS^^}" in
            '' | 'Y' | 'YES')
                return 1
            'N' | 'NO')
                return 0
        echo
    done
}

check_system() {
    if [ ! -d '/sys/firmware/efi/efivars' ]; then
        echo 'ERROR: System must be UEFI'
        exit 1
    fi

    if [ ! "$(ping -c1 archlinux.org)" ]; then
        echo 'ERROR: Check your internet connexion'
        exit 1
    fi
}

copy_system_config() {
    "$CP" -r "$CONFIG_DIR"/etc /etc
}

set_timezone() {
    ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    hwclock --systohc
    timedatectl set-ntp true
}

set_locale() {
    "$SED" 's/^#en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/; s/^#fr_FR.UTF-8 UTF-8$/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
}

set_hostname() {
    echo "$MYHOSTNAME" > /etc/hostname
    echo -e "127.0.0.1  localhost\n::1         localhost\n127.0.1.1   $MYHOSTNAME.localdomain $MYHOSTNAME" >> /etc/hosts
}

download_packages() {
    pacman "$PAC_OPT"yyu reflector
    systemctl start reflector
    pacman "$PAC_OPT" "${PACKAGES[@]}"
}

create_user() {
    echo -e "\n${BOLD}root passwd${NORMAL}"
    passwd

    useradd -mG wheel "$USERNAME"

    echo "${BOLD}$USERNAME passwd${NORMAL}"
    passwd "$USERNAME"
    "$SED" 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

download_special_packages() {
    "$SU" "$PWD/install_paru.sh && paru $PAC_OPT ${AUR_PACKAGES[@]}"
    ask 'Do you want tech packages?' && "$SU" "paru $PAC_OPT ${TECH_PACKAGES[@]}"
}

set_bootloader() {
    bootctl install
    "$CP" /usr/share/systemd/bootctl/arch.conf "$ENTRIES"
    echo -e 'default arch.conf\ntimeout 3\neditor  no' > /boot/loader/loader.conf

    "$SED" '/^$/d; /^#/d;' "$ENTRIES"arch.conf
    "$SED" "s/^options root=PARTUUID=XXXX rootfstype=XXXX add_efi_memmap$/options root=/dev/$DISK/" "$ENTRIES"arch.conf

    "$CP" "$ENTRIES"arch.conf "$ENTRIES"arch-fallback.conf
    "$SED" 's/Arch Linux$/Arch Linux (fallback initramfs)/; s/initramfs-linux.img$/initramfs-linux-fallback.img/' "$ENTRIES"arch-fallback.conf

    echo 'initrd  /intel-ucode.img' >> "$ENTRIES"arch.conf
}

enable_network() {
    systemctl enable NetworkManager
}

configure_graphics() {
    nvidia-xconfig
    "$SED" 's/^MODULES=()$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
}

copy_dotfiles() {
    ask 'Copy dotfiles?' && "$CP" -r "$CONFIG_DIR"/.* /home/"$USERNAME"

    # Oh My Zsh
    ask 'Install OMZ?' && "$SU" 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    ask 'Copy binaries?' && "$CP" "$CONFIG_DIR"/bin /home/"$USERNAME"
}

main() {
    check_system
    copy_system_config
    set_timezone
    set_locale
    set_hostname
    download_packages
    create_user
    download_special_packages
    set_bootloader
    enable_network
    configure_graphics
    copy_dotfiles
    echo "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot to exit${NORMAL}"
}

set -e
main
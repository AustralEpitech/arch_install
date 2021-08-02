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

SYS_ENTRIES_DIR='/boot/loader/entries/'
CP='cp -fv'
SED='sed -i'
SU="su $USERNAME -c"
PAC_OPT='--needed -S'

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
    reflector
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
        echo -en "${BOLD}:: $1 [Y/n] ${NORMAL}"
        read -r ANS
        case "${ANS^^}" in
            '' | 'Y' | 'YES')
                return 0
                ;;
            'N' | 'NO')
                return 1
                ;;
        esac
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
    $CP -r "$CONFIG_DIR"etc /
}

configure_clock() {
    ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    hwclock --systohc
    timedatectl set-ntp true
}

set_locale() {
    $SED 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/; s/^#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
}

set_hostname() {
    echo "$MYHOSTNAME" > /etc/hostname
    echo -e "127.0.0.1   localhost\n::1         localhost\n127.0.1.1   $MYHOSTNAME.localdomain $MYHOSTNAME" >> /etc/hosts
}

download_packages() {
    pacman --noconfirm ${PAC_OPT}yyu "${PACKAGES[@]}"
}

manage_users() {
    echo -e "\n${BOLD}root passwd${NORMAL}"
    passwd

    useradd -mG wheel "$USERNAME" -s $(which zsh)

    echo -e "${BOLD}$USERNAME passwd${NORMAL}"
    passwd "$USERNAME"

    $SED 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

download_special_packages() {
    mv /etc/sudoers /etc/sudoers.bak
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers

    ask 'Install OMZ?' && $SU 'echo |sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && exit'

    $SU "git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && cd /tmp/paru-bin && makepkg -si --noconfirm"

    $SU "paru --noconfirm $PAC_OPT ${AUR_PACKAGES[@]}"

    set +e
    $SU "paru $PAC_OPT ${TECH_PACKAGES[@]}"
    set -e

    mv /etc/sudoers.bak /etc/sudoers
}

set_bootloader() {
    bootctl install
    $CP /usr/share/systemd/bootctl/arch.conf "$SYS_ENTRIES_DIR"
    echo -e 'default arch.conf\ntimeout 3\neditor  no' > /boot/loader/loader.conf

    $SED '/^$/d; /^#/d; /^options/d' "$SYS_ENTRIES_DIR"arch.conf

    echo 'initrd  /intel-ucode.img' >> "$SYS_ENTRIES_DIR"arch.conf
    echo "options root=$(lsblk -p --list | awk '$7 == "/" {print $1}')" >> "$SYS_ENTRIES_DIR"arch.conf

    $CP "$SYS_ENTRIES_DIR"arch.conf "$SYS_ENTRIES_DIR"arch-fallback.conf
    $SED 's/Arch Linux$/Arch Linux (fallback initramfs)/; s/initramfs-linux.img$/initramfs-linux-fallback.img/' "$SYS_ENTRIES_DIR"arch-fallback.conf

}

enable_network() {
    systemctl enable NetworkManager
}

configure_graphics() {
    nvidia-xconfig
    $SED 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm/' /etc/mkinitcpio.conf
}

copy_dotfiles() {
    set +e

    ask 'Copy dotfiles?' && $CP -r "$CONFIG_DIR".[^.]* /home/"$USERNAME"
    ask 'Copy binaries?' && $CP -r "$CONFIG_DIR"bin /home/"$USERNAME"
}

self_destruction() {
    ask 'Delete script folder?' && rm -rf $(pwd)
    echo -e "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot${NORMAL}"
}

main() {
    set -e

    check_system
    copy_system_config
    configure_clock
    set_locale
    set_hostname
    download_packages
    manage_users
    download_special_packages
    set_bootloader
    enable_network
    configure_graphics
    copy_dotfiles
    self_destruction
}

main

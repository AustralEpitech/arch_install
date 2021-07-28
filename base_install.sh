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
    $CP -r "$CONFIG_DIR"/etc /
}

set_timezone() {
    ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    hwclock --systohc
    timedatectl set-ntp true
}

set_locale() {
    $SED 's/^#en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/; s/^#fr_FR.UTF-8 UTF-8$/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
}

set_hostname() {
    echo "$MYHOSTNAME" > /etc/hostname
    echo -e "127.0.0.1  localhost\n::1         localhost\n127.0.1.1   $MYHOSTNAME.localdomain $MYHOSTNAME" >> /etc/hosts
}

download_packages() {
    pacman --noconfirm --needed -Syyu "${PACKAGES[@]}"
}

create_user() {
    echo -e "\n${BOLD}root passwd${NORMAL}"
    passwd

    useradd -mG wheel "$USERNAME"

    echo -e "${BOLD}$USERNAME passwd${NORMAL}"
    passwd "$USERNAME"
    $SED 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

set_bootloader() {
    bootctl install
    $CP /usr/share/systemd/bootctl/arch.conf "$ENTRIES"
    echo -e 'default arch.conf\ntimeout 3\neditor  no' > /boot/loader/loader.conf

    $SED '/^$/d; /^#/d;' "$ENTRIES"arch.conf
    $SED "s+^options root=PARTUUID=XXXX rootfstype=XXXX add_efi_memmap\$+options root=/dev/$ROOT_DISK+" "$ENTRIES"arch.conf

    $CP "$ENTRIES"arch.conf "$ENTRIES"arch-fallback.conf
    $SED 's/Arch Linux$/Arch Linux (fallback initramfs)/; s/initramfs-linux.img$/initramfs-linux-fallback.img/' "$ENTRIES"arch-fallback.conf

    echo 'initrd  /intel-ucode.img' >> "$ENTRIES"arch.conf
}

enable_network() {
    systemctl enable NetworkManager
}

configure_graphics() {
    nvidia-xconfig
    $SED 's/^MODULES=()$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
}

copy_dotfiles() {
    set +e

    ask 'Install OMZ?' && $SU 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    ask 'Copy dotfiles?' && $CP -r "$CONFIG_DIR"/.* /home/"$USERNAME"

    ask 'Copy binaries?' && $CP "$CONFIG_DIR"/bin /home/"$USERNAME"

    set -e
}

main() {
    set -e

    check_system
    copy_system_config
    set_timezone
    set_locale
    set_hostname
    download_packages
    create_user
    set_bootloader
    enable_network
    configure_graphics
    copy_dotfiles
    echo -e "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot to exit${NORMAL}"
}

main

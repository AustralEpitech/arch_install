#!/usr/bin/bash

BOLD='\033[1m'
GREEN='\033[32m'
NORMAL='\033[0m'

CP='cp -fv'
SED='sed -i'
SU="su $username -c"
PAC_OPT='--noconfirm --needed -S'

boot_entries='/boot/loader/entries'

get_config() {
    local ANS

    less ./config
    read -rp ':: Press enter to start'
    source ./config
}

configure_clock() {
    ln -sf /usr/share/zoneinfo/"$tz" /etc/localtime
    hwclock --systohc
    timedatectl set-ntp true
}

set_locale() {
    for i in ${locales[*]}; do
        $SED "s/^#$i/$i/" /etc/locale.gen
    done
    locale-gen
    echo "LANG=$lang" > /etc/locale.conf
}

set_hostname() {
    echo "$hostname" > /etc/hostname
    echo -e "127.0.0.1   localhost\n::1         localhost\n127.0.1.1   $hostname" >> /etc/hosts
}

download_pkg() {
    $CP "etc/pacman.conf" /etc/
    pacman "${PAC_OPT}yyu" "${pkg[*]}"
}

manage_users() {
    zsh_path="$(which zsh)"
    echo "root:$root_passwd" | chpasswd

    if [ -n "$zsh_path" ]; then
        useradd -mG wheel "$username" -s "$zsh_path"
    else
        useradd -mG wheel "$username"
    fi

    echo "$username:$user_passwd" | chpasswd

    $SED 's/^# %wheel ALL=(ALL) ALL$/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

download_special_pkg() {
    mv /etc/sudoers /etc/sudoers.bak
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers

    [ "$omz" ] && $SU 'yes yes | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

    $SU "git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && cd /tmp/paru-bin && makepkg -si --noconfirm"

    [ "$aur_install" ] && $SU "paru $PAC_OPT ${aur_pkg[*]}"

    [ "$tech_install" ] && $SU "paru $PAC_OPT ${tech_pkg[*]}"

    mv /etc/sudoers.bak /etc/sudoers
}

set_bootloader() {
    bootctl install
    mkdir /etc/pacman.d/hooks -p && $CP etc/pacman.d/hooks/100-systemd-boot.hook
    $CP /usr/share/systemd/bootctl/arch.conf "$boot_entries"
    echo -e "$btl_opt" > /boot/loader/loader.conf

    $SED '/^$/d; /^#/d; /^options/d' "$boot_entries"/arch.conf

    if [ -n "$cpu" ]; then
        pacman "$PAC_OPT" "$cpu"-ucode
        echo "initrd  /$cpu-ucode.img" >> "$boot_entries"/arch.conf
    fi

    echo "options root=$(lsblk -p --list | awk '$7 == "/" {print $1}')" >> "$boot_entries"/arch.conf

    $CP "$boot_entries"/arch.conf "$boot_entries"/arch-fallback.conf
    $SED 's/Arch Linux$/Arch Linux (fallback initramfs)/; s/initramfs-linux.img$/initramfs-linux-fallback.img/' "$boot_entries"/arch-fallback.conf

}

enable_network() {
    systemctl enable NetworkManager
}

configure_graphics() {
    case "$gpu" in
        'nvidia')
            pacman "$PAC_OPT" nvidia{,-settings}
            mkdir /etc/pacman.d/hooks -p && $CP etc/pacman.d/hooks/nvidia.hook
            $SED "s/^modules=(/modules=(nvidia nvidia_modeset nvidia_uvm nvidia_drm/" /etc/mkinitcpio.conf
            nvidia-xconfig
            ;;
        'amd')
            pacman "$PAC_OPT" xf86-video-amdgpu
            $SED "s/^modules=(/modules=(amdgpu/" /etc/mkinitcpio.conf
            ;;
    esac
}

self_destruction() {
    [ "$rm_script" ] && rm -rfv "$(pwd)"

    echo -e "${BOLD}${GREEN}DONE. Ctrl+D, umount -R /mnt and reboot${NORMAL}"
}

main() {
    set -e

    get_config
    configure_clock
    set_locale
    set_hostname
    download_pkg
    manage_users
    download_special_pkg
    set_bootloader
    enable_network
    configure_graphics
    self_destruction
}

main

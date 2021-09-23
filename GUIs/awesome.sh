#!/usr/bin/bash

PACKAGES=(
    alacritty
    awesome
    flameshot
    gnome-themes-extra
    i3lock
    libreoffice-fresh
    lutris steam wine-{gecko,mono,staging} winetricks
    lxappearance
    network-manager-applet
    picom
    pipewire{,-alsa,-pulse} playerctl
    polkit-gnome
    redshift
    thunar
    xfce4-power-manager
    xorg-{server,setxkbmap,xbacklight,xev,xinit,xinput,xkill,xprop,xrandr,xrdb,xset} xclip
)

set -e

sudo pacman -S "$PACKAGES[@]"

echo -e '#!/bin/sh\n\nexec awesome' > "$HOME"/.xinitrc

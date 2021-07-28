#!/bin/bash

git clone https://aur.archlinux.org/paru-bin.git /tmp
cd /tmp/paru-bin
makepkg -si --noconfirm

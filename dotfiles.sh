#!/usr/bin/bash

set -e

config="git --git-dir $HOME/.dotfiles --work-tree $HOME"
repo="git@github.com:AustralEpitech/.dotfiles.git"
public_repo="https://github.com/AustralEpitech/.dotfiles.git"

select opt in public private; do
    if [ "$opt" == public ]; then
        repo="$public_repo"
    fi
    break;
done

git clone --bare "$repo" "$HOME"/.dotfiles

set +e
while ! $config checkout; do
    echo "Please remove conflicted files and press enter:"
    read -r
done
set -e

$config submodule update --init --recursive
$config config status.showUntrackedFiles no

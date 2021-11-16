################
### Dotfiles ###
################
config="git --git-dir $HOME/.dotfiles --work-tree $HOME"
repo="git@github.com:AustralEpitech/.dotfiles.git"
public_repo="https://github.com/AustralEpitech/.dotfiles.git"

select opt in public private; do
    if [ "$opt" == public ]; then
        repo="$public_repo"
    fi
done

git clone --bare "$repo" "$HOME"/.dotfiles

while [ $config checkout != 0 ]; do
    echo "Please remove conflicted files and press enter:"
    read -r
done

$config submodule update --init --recursive
$config config status.showUntrackedFiles no

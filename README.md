# Arch Installer

My personal Arch install script. It automates the step 2 of ArchWiki's [Installation guide](https://wiki.archlinux.org/title/Installation_guide) and more!

## How to

Follow the [Pre-installation](https://wiki.archlinux.org/title/Installation_guide#Pre-installation).  
Once you chrooted in the system, clone this script
```
cd /tmp
git clone https://github.com/AustralEpitech/arch_install.git
cd arch_install
```

**Review the config file before running any script!**

To install the base system, run:
```
./base_install.sh
```

If you want a post install script, login as a normal user and run (replace *desktopEnvironment* with your choice):
```
./desktopEnvironment/install.sh
```

For the dotfiles, run:
```
./dotfiles.sh
```

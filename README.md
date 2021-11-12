# Arch Installer

My personal Arch install script. It automates the step 2 of ArchWiki's [Installation guide](https://wiki.archlinux.org/title/Installation_guide) and more!

## How to

Follow the [Pre-installation](https://wiki.archlinux.org/title/Installation_guide#Pre-installation).\
Once you chrooted in the system, clone this script
```
git clone https://github.com/AustralEpitech/arch_install.git
```

**Review the config file associated before running any script to avoid suprises.**

To install the base system, run:
```
./base_install.sh
```

If you want to install awesomeWM, login as a normal user and run:
```
./awesomewm/awesome.sh
```

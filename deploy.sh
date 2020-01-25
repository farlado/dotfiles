#!/bin/sh
# Deploys my usual system

echo Getting your permission to use sudo...
sudo echo > /dev/null

echo Setting an important variable...
export XDG_CONFIG_HOME="$HOME/.config"

echo Checking whether this system is a ThinkPad...
isThinkPad="$(grep ThinkPad /sys/devices/virtual/dmi/id/product_version)"
# If it's a ThinkPad, we might need to do more...

echo Updating repositories and installing git...
sudo pacman --needed -Syu git

echo Configuring the dotfiles repository and submodules...
cd $XDG_CONFIG_HOME
git submodule sync
git submodule update --init --checkout --recursive
git config --local status.showUntrackedFiles no

for pkg in emacs-git yay; do
    if ! pacman -Q | grep $pkg; then
        echo Installing $pkg...
        cd $XDG_CONFIG_HOME/deploy/$pkg
        makepkg -si --noconfirm
        rm -rf pkg src $pkg*
    fi
done

echo Installing packages...
# If this is a ThinkPad, we need to set up the fan control software
[ "$isThinkPad" ] && {
    sys="gcc make cmake thinkfan simple-mtpfs ntfs-3g haveged tlp tlp-rdw intel-ucode"
} || sys="gcc make cmake simple-mtpfs ntfs-3g haveged tlp tlp-rdw intel-ucode"
audio="pulseaudio pulseaudio-bluetooth pulseaudio-alsa alsa-utils"
net="bluez bluez-utils networkmanager curl wget"
emacs="ghostscript aspell aspell-en texlive-most"
wm="xorg xorg-xinit xorg-drivers xorg-twm xorg-xclock xbanish xcompmgr arandr nm-connection-editor"
de="brightnessctl maim xclip i3lock-color"
looks="bibata-cursor-theme ant-dracula-gtk-theme gnome-themes-extra ttf-iosevka lxappearance-gtk3"
fonts="ttf-opensans ttf-ubuntu-font-family ttf-liberation ttf-dejavu noto-fonts noto-fonts-extra noto-fonts-emoji otf-ipafont wqy-microhei wqy-zenhei gohufont"
apps="firefox libreoffice-fresh musescore gimp telegram-desktop-bin discord mpv transmission-gtk musescore"
games="vulkan-intel mesa steam xonotic"
dev="python python-pylint python-jedi hy stack sbcl"
etc="ufetch zip unzip libtool ebook-tools mpd mpc"
yay --needed -Sy $sys $audio $net $emacs $wm $de $looks $fonts $apps $games $dev $etc

echo Configuring Haskell development environment...
cd $HOME
stack init && stack setup

echo Configuring services...
[ "$ifThinkPad" ] && {
    services="haveged NetworkManager thinkfan bluetooth"
} || services="haveged NetworkManager bluetooth"
for service in $services; do
    sudo systemctl enable $service
done

echo Generating boot image...
sudo cp $XDG_CONFIG_HOME/deploy/loader.conf /boot/loader/loader.conf
sudo cp $XDG_CONFIG_HOME/deploy/arch.conf /boot/loader/entries/arch.conf
sudo mkinitcpio -p linux

echo Installing and configuring shells, we may need your password...
yay --needed -S zsh dash
sudo ln -sf dash /bin/sh
chsh -s /bin/zsh $USER

echo Tangling dotfiles...
cd $XDG_CONFIG_HOME
emacs --eval '(progn (org-babel-tangle-file "literate-dotfiles.org") (kill-emacs))'

echo Generating dump image for Emacs...
emacs --batch -q -l $XDG_CONFIG_HOME/emacs/lisp/pdumper.el

echo Everything /should/ be set up now...
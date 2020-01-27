#!/bin/sh
# Deploys my usual system

echo Getting your permission to use sudo...
sudo echo > /dev/null

echo Setting an important variable...
export XDG_CONFIG_HOME="$HOME/.config"

# If it's a ThinkPad, we might need to do more.
echo Checking whether this system is a ThinkPad...
isThinkPad="$(grep ThinkPad /sys/devices/virtual/dmi/id/product_version)"

echo Updating repositories and installing git...
sudo pacman --noconfirm --needed -Syu git

echo Installing yay...
git clone https://aur.archlinux.org/yay /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm

echo Installing Emacs...
cd $XDG_CONFIG_HOME/dotfiles/emacs-git
makepkg -si --noconfirm
rm -rf pkg src emacs-git*

echo Installing packages...
# If this is a ThinkPad, we need to set up the fan control software
[ "$isThinkPad" ] && {
    sys="gcc make cmake thinkfan simple-mtpfs ntfs-3g haveged tlp tlp-rdw intel-ucode"
} || sys="gcc make cmake simple-mtpfs ntfs-3g haveged tlp tlp-rdw intel-ucode"
shells="zsh dash"
audio="pulseaudio pulseaudio-bluetooth pulseaudio-alsa alsa-utils"
net="bluez bluez-utils networkmanager curl wget"
emacs="ghostscript aspell aspell-en texlive-most"
wm="xorg xorg-xinit xorg-drivers xorg-twm hsetroot conky xbanish xcompmgr arandr nm-connection-editor"
de="brightnessctl maim xclip i3lock-color"
looks="bibata-cursor-theme ant-dracula-gtk-theme gnome-themes-extra ttf-iosevka lxappearance-gtk3"
fonts="ttf-opensans ttf-ubuntu-font-family ttf-liberation ttf-dejavu noto-fonts noto-fonts-extra noto-fonts-emoji otf-ipafont wqy-microhei wqy-zenhei gohufont"
apps="firefox libreoffice-fresh musescore gimp telegram-desktop-bin discord mpv transmission-gtk musescore"
games="vulkan-intel mesa steam xonotic"
dev="python python-pylint python-jedi hy stack sbcl"
etc="ufetch zip unzip libtool ebook-tools mpd mpc"
yay --noconfirm --needed -Sy $sys $shells $audio $net $emacs $wm $de $looks $fonts $apps $games $dev $etc

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
sudo cp $XDG_CONFIG_HOME/dotfiles/deploy/loader.conf /boot/loader/loader.conf
sudo cp $XDG_CONFIG_HOME/dotfiles/deploy/arch.conf /boot/loader/entries/arch.conf
sudo mkinitcpio -p linux

echo Configuring shells, we may need your password...
sudo ln -sf dash /bin/sh
chsh -s /bin/zsh $USER

echo Grabbing a zsh module...
git clone https://github.com/zsh-users/zsh-syntax-highlighting $XDG_CONFIG_HOME/zsh/zsh-syntax-highlighting

echo Cloning Emacs configuration...
git clone https://github.com/farlado/dotemacs $XDG_CONFIG_HOME/emacs

echo Tangling dotfiles...
cd $XDG_CONFIG_HOME/dotfiles
emacs --batch \
      --eval "(require 'org)" \
      --eval "(setq org-confirm-babel-evaluate nil)" \
      --eval "(defmacro user-emacs-file (file) (expand-file-name file user-emacs-directory))" \
      --eval "(defmacro user-home-file (file) (expand-file-name file (getenv \"HOME\")))" \
      --eval "(defmacro user-config-file (file) (expand-file-name file  (getenv \"XDG_CONFIG_HOME\")))" \
      --eval '(org-babel-tangle-file "literate-dotfiles.org")'

echo Generating dump image for Emacs...
emacs --batch -q -l $XDG_CONFIG_HOME/emacs/lisp/pdumper.el

echo You will have to now open Emacs and enter: \`C-c C-M-e C-c C-v t\`

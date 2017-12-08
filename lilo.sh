#!/bin/bash

clear

echo "  Installing Pacaur..."
yaourt -S --noconfirm pacaur > /dev/null
echo "  Updating the system..."
pacaur -Syuu --noconfirm --noedit --silent > /dev/null
echo "  Installing the window manager..."
pacaur -S --noconfirm --noedit --silent bspwm sxhkd &> /dev/null
echo "  Installing the terminal..."
pacaur -S --noconfirm --noedit --silent termite tmux feh htop openssh rsync scrot &> /dev/null
echo "  Installing some fonts..."
pacaur -S --noconfirm --noedit --silent phallus-fonts-git bdf-creep gohufont
echo "  Installing the text editor..."
pacaur -S --noconfirm --noedit --silent neovim micro
echo "  Installing Firefox..."
pacaur -S --noconfirm --noedit --silent firefox-nightly &> /dev/null
echo "  Installing Netflix..."
pacaur -S --noconfirm --noedit --silent torrentflix peerflix addic7ed-cli &> /dev/null
echo "  Installing Reddit..."
pacaur -S --noconfirm --noedit --silent rtv &> /dev/null
echo "  Installing the password manager..."
pacaur -S --noconfirm --noedit --silent kpcli &> /dev/null
echo "  Installing the file manager..."
pacaur -S --noconfirm --noedit --silent nnn &> /dev/null
echo "  Installing the email client..."
pacaur -S --noconfirm --noedit --silent mutt &> /dev/null
echo "  Installing the rss client..."
pacaur -S --noconfirm --noedit --silent newsbeuter &> /dev/null
echo "  Installing extras..."
pacaur -S --noconfirm --noedit --silent concalc &> /dev/null
echo "  Installing the torrent client..."
pacaur -S --noconfirm --noedit --silent qbittorrent &> /dev/null
echo "  Installing the audio manager..."
pacaur -S --noconfirm --noedit --silent alsa-utils alsa-lib &> /dev/null
echo "  Installing some useful desktop shit..."
pacaur -S --noconfirm --noedit --silent dunst i3lock rofi redshift unclutter libnotify-id lemonbar-xft-git hsetroot &> /dev/null
echo "  Installing useful programming stuff..."
pacaur -S --noconfirm --noedit --silent python python2 python-pip python2-pip jdk8-openjdk java-openjfx ruby &> /dev/null
echo "  Installing the video player..."
pacaur -S --noconfirm --noedit --silent mpv &> /dev/null
echo "  Installing the login manager..."
pacaur -S --noconfirm --noedit --silent lightdm &> /dev/null
echo "  Installing Libre Office..."
pacaur -S --noconfirm --noedit --silent libreoffice-fresh &> /dev/null
echo "  Installing design software..."
pacaur -S --noconfirm --noedit --silent gimp gravit &> /dev/null
echo "  Installing compression software..."
pacaur -S --noconfirm --noedit --silent zip unzip unrar p7zip &> /dev/null
echo "  Installing external harddrive related software..."
pacaur -S --noconfirm --noedit --silent exfat-utils ntfs-3g udiskie &> /dev/null
pacaur -S --noconfirm --noedit --silent acpi &> /dev/null
if [ -d /proc/acpi/battery/BAT* ]
then
  echo "  Installing the battery manager..."
  pacaur -S --noconfirm --noedit --silent powertop tlp &> /dev/null
  echo "  Installing touchpad packages..."
  pacaur -S --noconfirm --noedit --silent xf86-input-synaptics xf86-input-libinput &> /dev/null
fi

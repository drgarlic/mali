#!/bin/bash

clear

echo "  Installing Pacaur..."
yaourt -S --noconfirm pacaur > /dev/null
echo "  Updating the system..."
pacaur -Syuu --noconfirm --noedit --silent > /dev/null
echo "  Installing the window manager..."
pacaur -S --noconfirm --noedit --silent openbox-patched &> /dev/null
echo "  Installing the terminal..."
pacaur -S --noconfirm --noedit --silent termite tmux feh htop openssh rsync scrot &> /dev/null
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
echo "  Installing Python..."
pacaur -S --noconfirm --noedit --silent python python2 python-pip python2-pip &> /dev/null
echo "  Installing Java..."
pacaur -S --noconfirm --noedit --silent jdk8-openjdk java-openjfx &> /dev/null
echo "  Installing the video player..."
pacaur -S --noconfirm --noedit --silent mpv &> /dev/null
echo "  Installing the login manager..."
pacaur -S --noconfirm --noedit --silent lightdm &> /dev/null
echo "  Installing Libre Office..."
pacaur -S --noconfirm --noedit --silent libreoffice-fresh &> /dev/null
echo "  Installing Gimp..."
pacaur -S --noconfirm --noedit --silent gimp &> /dev/null
echo "  Installing compression software..."
pacaur -S --noconfirm --noedit --silent zip unzip unrar p7zip &> /dev/null
echo "  Installing external harddrive related software..."
pacaur -S --noconfirm --noedit --silent exfat-utils ntfs-3g udiskie &> /dev/null
if [ "$laptop" = true ]
then
  echo "  Installing the battery manager..."
  pacaur -S --noconfirm --noedit --silent powertop acpi tlp &> /dev/null
  echo "  Installing touchpad packages..."
  pacaur -S --noconfirm --noedit --silent xf86-input-synaptics xf86-input-libinput &> /dev/null
fi

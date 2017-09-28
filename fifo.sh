#!/bin/bash

clear
echo -e "\n    Welcome.
  This script will guide you during this very painful installation of Arch Linux.
  Put your belt on, take a deep breath and please try not to panic."
read -p "\n  Press enter to continue"

echo -e "\n\n    Chapter I - Preparations\n"
echo "  Checking the internet connection..."
until ping -c 1 archlinux.org > /dev/null
do
  echo -e "\nPlug an ethernet cable"
  read -p "Press enter to continue"
  systemctl stop dhcpcd
  systemcll start dhcpcd
  sleep 5
  ping -c 1 archlinux.org > /dev/null
done

echo "  Updating the system clock..."
timedatectl set-ntp true

echo -e "\n\n    Chapter II - Partitions\n"
lsblk
read -p "  Enter the name of the disered path (Example : sda): " sd

echo "  Destroying the partition table..."
sgdisk -Z /dev/sdb > /dev/null
echo -e "  Formatting the \"boot\" partition..."
sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd > /dev/null
ram=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
echo -e "  Formatting the \"swap\" partition..."
sgdisk -n 0:0:+${ram}G -t 0:8200 -c 0:"swap" /dev/$sd > /dev/null
echo -e "  Formatting the \"arch\" partition..."
sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd > /dev/null
echo "  Updating the partition table..."
sgdisk -p /dev/$sd > /dev/null
partprobe /dev/$sd > /dev/null
fdisk -l /dev/$sd > /dev/null

sd1=$sd\1
echo -e "  Formatting the \"boot\" partition..."
mkfs.fat -F32 /dev/$sd1 > /dev/null
echo -e "  Formatting the \"swap\" partition..."
sd2=$sd\2
mkswap /dev/$sd2 > /dev/null
swapon /dev/$sd2
echo -e "Formatting the \"arch\" partition..."
sd3=$sd\3
mkfs.ext4 -F /dev/$sd3 > /dev/null

echo -e "  Mounting \"/mnt\"..."
mount /dev/$sd3 /mnt
echo -e "  Creating \"/mnt/boot\"..."
mkdir /mnt/boot
echo -e "  Creating \"/mnt/home\"..."
mkdir /mnt/home
echo -e "  Mounting \"/mnt/boot\"..."
mount /dev/$sd1 /mnt/boot
echo -e "  Mounting \"/mnt/home\"..."
mount /dev/$sd3 /mnt/home

echo -e "\n\n    Chapter III - Installation\n"

echo "  Installing the base packages..."
pacstrap /mnt base base-devel > /dev/null 2>&1

echo -e "\n\n    Chapter IV - Configure the system\n"

echo "  Generating the fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "  Setting the time..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

echo "  Setting the language..."
arch-chroot /mnt sed -i '/'\#en_US.UTF-8'/s/^#//' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

echo "  Creating the hostname..."
read -p "  Enter a hostname : " hostnm
arch-chroot /mnt echo $hostnm > /mnt/etc/hostname
arch-chroot /mnt echo "127.0.1.1	$hostnm.localdomain     $hostnm" >> /mnt/etc/hosts

echo -e "  Updating \"pacman.conf\"..."
arch-chroot /mnt sed -i '/'multilib\]'/s/^#//' /etc/pacman.conf
arch-chroot /mnt sed -i '/\[multilib\]/ a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
arch-chroot /mnt echo "[archlinuxfr]" >> /mnt/etc/pacman.conf
arch-chroot /mnt echo "SigLevel = Never" >> /mnt/etc/pacman.conf
arch-chroot /mnt echo "Server = http://repo.archlinux.fr/\$arch" >> /mnt/etc/pacman.conf
echo "  Updating Pacman..."
arch-chroot /mnt pacman -Sy > /dev/null
echo "  Installing Yaourt..."
arch-chroot /mnt pacman -Syy yaourt > /dev/null
echo "  Installing basic packages..."
arch-chroot /mnt pacman -Syy zip unzip p7zip vim mc alsa-utils ntfs-3g exfat-util bash-completion > /dev/null
echo "  Installing the Intel microcode package..."
arch-chroot /mnt pacman -Syy intel-ucode > /dev/null
echo "  Installing the network manager..."
arch-chroot /mnt pacman -Syy networkmanager 
arch-chroot /mnt systemctl enable NetworkManager
echo "  Installing wifi packages..."
arch-chroot /mnt pacman -Syy iw wpa_supplicant dialog > /dev/null
echo "  Installing video drivers..."
arch-chroot /mnt pacman -Syy xf86-video-intel mesa > /dev/null
echo "  Installing wifi packages..."
arch-chroot /mnt pacman -Syy xorg-server xorg-server-utils xorg-xinit > /dev/null

xf86-input-synaptics xf86-input-libinput `#Touchpad`
termite `#Terminal` \
#tor \
rtorrent `#Torrent cli` \
tmux `#Terminal multiplexer` \
neovim `#Text editor` \
firefox `#Browser` \
alsa-utils alsa-lib pusleaudio pulseaudio-alsa `#Sound` \
dunst `#Notification server` \
udiskie `#Automount` \
i3lock `#Lockscreen` \
python python2 python-pip python2-pip `#Python` \
android-tools `#ADB` \
mpv `#VLC` \
ranger w3m `#File manager` \
slim archlinux-themes-slim `#Login` \
feh `#Image viewer` \
zip unzip unrar `#Compression` \
redshift `#Flux` \
htop `#Sys info` \
xautolock `#Autolock` \
scrot `#Screenshots` \
openssh `#SSH` \
rsync `#Sync files` \
exfat-utils `#Mount exfat`
ntfs-3g `#Read and write ntfs` \
unclutter `#Hide the mouse` \
xsel `#Copy` \
ruby \
npm `#Magnet dependencie` \
powertop acpi tlp `#Battery` \
rofi `#Launcher` \
jdk8-openjdk java-openjfx `#Java` \
libreoffice-fresh `#Word processor` \
gimp `#Graphical editor` \ 
mutt `#Mail` \
youtube-dl `#Rtv dependencie` \
newsbeuter `#Rss` \
openvpn `#Vpn` \
intellij-idea-community-edition `#Java IDE` \
gtk-engine-murrine `#Gtk`

echo "  Enter root's password: "
arch-chroot /mnt passwd
read -p "  Enter a username: " usr
echo "  Creating the user..."
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/ a Defaults rootpw' /etc/sudoers 
echo "  Enter the user's password: "
arch-chroot /mnt passwd $usr

echo -e "  Setting the boot loader..."
arch-chroot /mnt bootctl install > /dev/null
arch-chroot /mnt echo -e "title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=/dev/$sd3 pcie_aspm=force rw" >> /mnt/boot/loader/entries/arch.conf

read -p "\n\n  Done.\n\n  Press enter to continue"
umount -R /mnt
shutdown

#!/bin/bash

clear
echo -e "\n    Welcome.
  This script will guide you during this very painful installation of Arch Linux.
  Put your belt on, take a deep breath and please try not to panic."
read -p "`echo -e "\n  "`Press enter to continue"

echo -e "\n\n    Chapter I - Preparations\n"

read -p "  Do you want to use wifi (Y/n) ? `echo $'\n> '`" wifi
wifi=${wifi,,}  #Lowercase
wifi=${wifi::1} #First letter
while [[ "$wifi" != "y" && "$wifi" != "n" ]]
do
  read -p "  Wrong answer, try again (Y/n) `echo $'\n> '`" wifi
done
while [ "$wifi" = "y" ]
do
  wifi-menu
  if [ $? != 0 ]
  then
    read -p "  Do you want to try again (Y/n)?  `echo $'\n> '`" $again
    again=${again,,}
    wifi=${again::1}
  else
    wifi="n"
  fi
done

echo "  Checking the internet connection..."
until ping -c 1 archlinux.org &> /dev/null
do
  echo -e "  Plug an ethernet cable"
  read -p "  Press enter to continue"
  systemctl stop dhcpcd
  systemctl start dhcpcd
  sleep 5
done

echo "  Checking if booted as bios or uefi..."
ls /sys/firmware/efi/efivars > /dev/null
if [ $? = 0 ]
then
  uefi=true
else
  uefi=false
fi

# pacman -Sy --noconfirm acpi > /dev/null 
# if [ $? = 0 ]
# then
#   laptop=true
# else
#   laptop=false
# fi

echo "  Updating the system clock..."
timedatectl set-ntp true

echo -e "\n\n    Chapter II - Partitions\n"
lsblk
read -p "  Enter the name of the disered path (Example : sda) `echo $'\n> sd'`" sd
sd=${sd,,}
while [[ "$sd" != [a-e] ]]
do
  read -p "  Wrong answer, try again `echo $'\n> '`" sd
done
sd=sd$sd

echo "  Destroying the partition table..."
sgdisk -Z /dev/$sd > /dev/null
echo -e "  Creating the \"boot\" partition..."
if [ $uefi = true ]
then
  sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd &> /dev/null
else
  sgdisk -n 0:0:+500M -t 0:ef02 -c 0:"boot" /dev/$sd &> /dev/null
fi
ram=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
echo -e "  Creating the \"swap\" partition..."
sgdisk -n 0:0:+${ram}G -t 0:8200 -c 0:"swap" /dev/$sd &> /dev/null
echo -e "  Creating the \"arch\" partition..."
sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd &> /dev/null
echo "  Updating the partition table..."
sgdisk -p /dev/$sd > /dev/null
partprobe /dev/$sd > /dev/null
fdisk -l /dev/$sd > /dev/null

sd1=$sd\1
echo -e "  Formatting the \"boot\" partition..."
if [ "$uefi" = true ]
then
  mkfs.fat -F32 /dev/$sd1 &> /dev/null
else
  mkfs.ext2 -F /dev/$sd1 &> /dev/null
fi
echo -e "  Formatting the \"swap\" partition..."
sd2=$sd\2
mkswap /dev/$sd2 &> /dev/null
swapon /dev/$sd2 &> /dev/null
echo -e "  Formatting the \"arch\" partition..."
sd3=$sd\3
mkfs.ext4 -F /dev/$sd3 &> /dev/null

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

echo "  Updating the mirror list..."
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup      
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

echo "  Installing the base packages..."
pacstrap /mnt base base-devel &> /dev/null

echo -e "\n\n    Chapter IV - Configure the system\n"

echo "  Generating the fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "  Setting the time..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

echo "  Setting the language..."
arch-chroot /mnt sed -i '/'\#en_US.UTF-8'/s/^#//' /etc/locale.gen
arch-chroot /mnt locale-gen > /dev/null
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf > /dev/null

echo "  Creating the hostname..."
read -p "  Enter a hostname : " hostnm
arch-chroot /mnt echo $hostnm > /mnt/etc/hostname
arch-chroot /mnt echo "127.0.1.1	$hostnm.localdomain     $hostnm" >> /mnt/etc/hosts

echo -e "  Updating \"pacman.conf\"..."
arch-chroot /mnt sed -i '/'multilib\]'/s/^#//' /etc/pacman.conf
arch-chroot /mnt sed -i '/\[multilib\]/ a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
arch-chroot /mnt echo "[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch" >> /mnt/etc/pacman.conf
echo "  Updating Pacman..."
arch-chroot /mnt pacman -Sy &> /dev/null
echo "  Installing Yaourt..."
arch-chroot /mnt pacman -Syy --noconfirm yaourt &> /dev/null
echo "  Installing the Intel microcode package..."
arch-chroot /mnt pacman -Syy --noconfirm intel-ucode &> /dev/null
echo "  Installing the network manager..."
arch-chroot /mnt pacman -Syy --noconfirm networkmanager &> /dev/null
arch-chroot /mnt systemctl enable NetworkManager &> /dev/null
echo "  Installing wifi packages..."
arch-chroot /mnt pacman -Syy --noconfirm iw wpa_supplicant dialog &> /dev/null
echo "  Installing video drivers..."
arch-chroot /mnt pacman -Syy --noconfirm xf86-video-intel mesa &> /dev/null
echo "  Installing X..."
arch-chroot /mnt pacman -Syy --noconfirm xorg-server xorg-server-utils xorg-xinit xautolock &> /dev/null
echo "  Installing the terminal..."
arch-chroot /mnt pacman -Syy --noconfirm termite tmux neovim feh htop openssh rsync newsbeuter mutt &> /dev/null
echo "  Installing the torrent client..."
arch-chroot /mnt pacman -Syy --noconfirm qbittorrent &> /dev/null
echo "  Installing the audio manager..."
arch-chroot /mnt pacman -Syy --noconfirm alsa-utils alsa-lib &> /dev/null
echo "  Installing some useful desktop shit..."
arch-chroot /mnt pacman -Syy --noconfirm dunst i3lock rofi redshift scrot unclutter &> /dev/null
echo "  Installing Python..."
arch-chroot /mnt pacman -Syy --noconfirm python python2 python-pip python2-pip &> /dev/null
echo "  Installing Java..."
arch-chroot /mnt pacman -Syy --noconfirm jdk8-openjdk java-openjfx &> /dev/null
echo "  Installing the video player..."
arch-chroot /mnt pacman -Syy --noconfirm mpv &> /dev/null
echo "  Installing the login manager..."
arch-chroot /mnt pacman -Syy --noconfirm lightdm &> /dev/null
echo "  Installing Libre Office..."
arch-chroot /mnt pacman -Syy --noconfirm libreoffice-fresh &> /dev/null
echo "  Installing Gimp..."
arch-chroot /mnt pacman -Syy --noconfirm gimp &> /dev/null
echo "  Installing compression software..."
arch-chroot /mnt pacman -Syy --noconfirm zip unzip unrar p7zip &> /dev/null
echo "  Installing external harddrive related software..."
arch-chroot /mnt pacman -Syy --noconfirm exfat-utils ntfs-3g udiskie &> /dev/null
if [ $laptop = true ]
then
  echo "  Installing the battery manager..."
  arch-chroot /mnt pacman -Syy --noconfirm powertop acpi tlp &> /dev/null
  echo "  Installing touchpad packages..."
  arch-chroot /mnt pacman -Syy --noconfirm xf86-input-synaptics xf86-input-libinput &> /dev/null
fi
arch-chroot /mnt pacman -Syyu--noconfirm &> /dev/null

read -p "`echo -e "\n  "`Press enter to continue" #DEBUG

echo "  Installing pacaur"
arch-chroot /mnt yaourt -S --noconfirm pacaur

read -p "`echo -e "\n  "`Press enter to continue" #DEBUG

arch-chroot /mnt pacaur -Sy --noconfirm \
concalc `#CLI calculator` \
libnotify-id `#Notifications` \
lemonbar-xft-git `#Bar` \
hsetroot `#Wallpaper` \
kpcli `#Keepass` \
addic7ed-cli `#Subtitles` \
rtv `#Reddit` \
torrentflix peerflix \
firefox-nightly \
nnn \
openbox-patched

read -p "`echo -e "\n  "`Press enter to continue" #DEBUG

echo "  Enter root's password: "
arch-chroot /mnt passwd
read -p "  Enter a username: " usr
echo "  Creating the user..."
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/ a Defaults rootpw' /etc/sudoers 
echo "  Enter the user's password: "
arch-chroot /mnt passwd $usr

read -p "`echo -e "\n  "`Press enter to continue" #DEBUG

echo -e "  Setting the boot loader..."
if [ $uefi = true ]
then
  arch-chroot /mnt bootctl install > /dev/null
  arch-chroot /mnt echo -e "title Arch Linux
  linux /vmlinuz-linux
  initrd /intel-ucode.img
  initrd /initramfs-linux.img
  options root=/dev/$sd3 pcie_aspm=force rw" >> /mnt/boot/loader/entries/arch.conf
else
  arch-chroot /mnt pacman -S grub
  mkinitcpio -p linux
  arch-chroot /mnt grub-install  --no-floppy --recheck /dev/$sd
  if [ $? != 0 ]
  then
    arch-chroot /mnt grub-install  --no-floppy --recheck /dev/$sd
  fi
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

read -p "`echo -e "\n  "`Press enter to continue" #DEBUG

read -p "\n\n  Done.\n\n  Press enter to continue"
umount -R /mnt
shutdown

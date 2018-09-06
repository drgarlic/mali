#!/usr/bin/env bash
#
#    ^   '||   '||'  //''\
#   //\   ||    ||   ``--.
#  //''\  ||_| .||.  \\__/
#
# Description:              A painless arch installer
# Dependencies:             none
# Optionnal dependencies:   none
# Author:                   gawlk
# Contributors:             none

# ---
# TODO
# ---
#
# - Clean the code

# ---
# SETUP
# ---

# Global variables
uefi=false
usb="n"

# ---
# LOCAL
# ---

any_key() { 
    read -n 1 -s -r -p "    Press any key to continue"
    printf "\n"
}

welcome() {
    clear

    printf "\n    Hi, I'm Alis.\n\n"
    printf "    I'm here to install arch for you. Just take a seat and chill.\n"
    printf "    But first, I'm gonna a few very important questions,\n"
    printf "    I'm a genius of course but.. not a telepath.\n\n"    
}

process_input(){
}

download_log() {
    ping -c 1 www.google.com &> /dev/null || ( printf "ERROR: No internet, please fix it and try again." && exit 1 )
    
    rm log &> /dev/null
    wget -q --timeout=20 https://raw.githubusercontent.com/gawlk/log/master/log

    . log
}

# ---
# MAIN
# ---

main() {
    # Chapter 0 - Initialisation 

    welcome

    input

    download_log

    # Chapter 1 - Preparations

    printf "\n    ---\n\n    Chapter I - Preparations\n\n"

    log.info "Updating the system clock..."
    timedatectl set-ntp true

    printf "    Are you installing Arch on a external storage ?\n"
    read usb

    log.info "Checking if UEFI..."
    [[ "$usb" == "n" ]] && ls /sys/firmware/efi/efivars &> /dev/null && uefi=true

    printf "\n    ---\n\n    Chapter 2 - Partitions\n\n"

    lsblk
    printf "    On which partition do you want to install Arch ? (Example: sda)\n"
    read partition
    partition="$( lsblk | grep "disk" | grep -o "[0-9a-zA-Z]*$partition[0-9a-zA-Z]*" )"
    while [[ -z "$partition" ]] 
    do
        #do something
        partition="1"
    done

    between="" && [[ "$partion" == [0-9a-zA-Z]*[0-9] ]] && between="p"
    partition1=${partion}${between}1
    partition3=${partion}${between}2
    [[ "$usb" == "n" ]] && partition2=${partion}${between}2 && partition3=${partion}${between}3

    log.info "Cleaning the partition table..."
    wipefs -a /dev/$partition1 &> /dev/null
    [[ "$usb" == "n" ]] && wipefs -a /dev/$partition2 &> /dev/null
    wipefs -a /dev/$partition3 &> /dev/null
    wipefs -a /dev/$partition &> /dev/null

    swap=$( free -m | grep "Mem" | awk '{ print $2 }'
    (( ( swap / 2000 ) + 1 ))

    log.info "Creating a new partition table..."


}

main 

exit 0

swap=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
if [ "$uefi" = true ]
then
  sgdisk -Z /dev/$sd > /dev/null
  echo -e "  Creating the \"boot\" partition..."
  sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd &> /dev/null
  echo -e "  Creating the \"swap\" partition..."
  sgdisk -n 0:0:+${swap}G -t 0:8200 -c 0:"swap" /dev/$sd &> /dev/null
  echo -e "  Creating the \"arch\" partition..."
  sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd &> /dev/null
  sgdisk -p /dev/$sd &> /dev/null
else
  [[ "$usb" != "y" ]] && echo "o
n
p
1

+500M
n
p
2

+${swap}G
n
p
3


w" | fdisk /dev/$sd > /dev/null || echo "o
n
p
1

+500M
n
p
2


w" | fdisk /dev/$sd > /dev/null
  fdisk -l /dev/$sd > /dev/null
fi
echo "  Updating the partition table..."
partprobe /dev/$sd > /dev/null

echo -e "  Formatting the \"boot\" partition..."
if [[ "$usb" != "y" ]]
then
  if [ "$uefi" = true ]
  then
    mkfs.fat -F32 /dev/$sd1 &> /dev/null
  else
    mkfs.ext2 -F /dev/$sd1 &> /dev/null
  fi
  
  echo -e "  Formatting the \"swap\" partition..."
  mkswap /dev/$sd2 &> /dev/null
  swapon /dev/$sd2 &> /dev/null
  
  echo -e "  Formatting the \"arch\" partition..."
  mkfs.ext4 -F /dev/$sd3 &> /dev/null
else
  mkfs.ext4 -O "^has_journal" /dev/$sd1 &> /dev/null
  
  echo -e "  Formatting the \"arch\" partition..."
  mkfs.ext4 -O "^has_journal" /dev/$sd3 &> /dev/null
fi

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

read -p "  Do you want to update the mirrorlist (Y/n) ? `echo $'\n> '`" mirror
input $mirror
if [ "$mirror" == "y" ]
then
  echo "  Updating the mirror list..."
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup      
  rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
fi

echo "  Installing the operating system..."
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

echo "  Enter root's password: "
until arch-chroot /mnt passwd
do
  :
done
read -p "  Enter a username: " usr
echo "  Creating the user..."
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/ a Defaults rootpw' /etc/sudoers 
echo "  Enter the user's password: "
until arch-chroot /mnt passwd $usr
do 
  :
done

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
# echo "  Installing the network manager..."
# arch-chroot /mnt pacman -Syy --noconfirm networkmanager &> /dev/null
# arch-chroot /mnt systemctl enable NetworkManager &> /dev/null
echo "  Installing wifi packages..."
arch-chroot /mnt pacman -Syy --noconfirm iw wpa_supplicant dialog &> /dev/null
echo "  Installing video drivers..."
arch-chroot /mnt pacman -Syy --noconfirm xf86-video-intel mesa &> /dev/null
echo "  Installing X..."
arch-chroot /mnt pacman -Syy --noconfirm xorg-server xorg-xinit xautolock xorg-xkill &> /dev/null

echo -e "  Setting the boot loader..."
if [ "$uefi" = true ]
then
  arch-chroot /mnt bootctl install &> /dev/null
  arch-chroot /mnt echo -e "title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=/dev/$sd3 pcie_aspm=force rw" > /mnt/boot/loader/entries/arch.conf
else
  if [[ "$usb" == "y" ]]
  then
    echo -e "  Setting mkinitcpio"
    arch-chroot /mnt sed -i '52s/autodetect modconf block/block autodetect modconf/' /etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -p linux
  fi
  
  arch-chroot /mnt pacman -Syy --noconfirm grub &> /dev/null
  echo -e "  Installing Grub..."
  arch-chroot /mnt grub-install --target=i386-pc /dev/$sd &> /dev/null
  if [ $? != 0 ]
  then
    echo -e "  Something went wrong, reinstalling Grub..."
    arch-chroot /mnt grub-install --force --recheck --target=i386-pc /dev/$sd &> /dev/null
  fi
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg &> /dev/null
  
  [[ "$usb" == "y" ]] && uuid=$(blkid -o value -s UUID /dev/$sd3) && arch-chroot /mnt echo -e "LABEL Arch
    MENU LABEL Arch Linux
    LINUX ../vmlinuz-linux
    APPEND root=UUID=$uuid ro
    INITRD ../initramfs-linux.img" > /mnt/boot/grub/menu.lst
fi

echo -e "\n\n  Done.\n"
read -p "  Press enter to continue"
umount -R /mnt
shutdown -h now

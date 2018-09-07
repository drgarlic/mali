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
usb=false

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
    printf "    Are you installing Arch on a external storage ?\n"
    read usb

    lsblk
    printf "    On which partition do you want to install Arch ? (Example: sda)\n"
    read partition
    partition="$( lsblk | grep "disk" | grep -o "[0-9a-zA-Z]*$partition[0-9a-zA-Z]*" )"
    while [[ -z "$partition" ]] 
    do
        #do something
        partition="1"
    done

    read -p "  Do you want to update the mirrorlist (Y/n) ? `echo $'\n> '`" mirror
    input $mirror

    read -p "  Enter a hostname : " hostnm

    read -p "  Enter a username: " usernm

    # userpw

    # rootpw
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

    log.info "Checking if UEFI..."
    [[ "$usb" == "n" ]] && ls /sys/firmware/efi/efivars &> /dev/null && uefi=true

    printf "\n    ---\n\n    Chapter 2 - Partitions\n\n"

    between="" && [[ "$partion" == [0-9a-zA-Z]*[0-9] ]] && between="p"
    partition1=${partion}${between}1
    partition3=${partion}${between}2
    [[ "$usb" == "n" ]] && partition2=${partion}${between}2 && partition3=${partion}${between}3

    log.info "Cleaning the partition table..."
    wipefs -a /dev/$partition1 &> /dev/null
    [[ "$usb" == "n" ]] && wipefs -a /dev/$partition2 &> /dev/null
    wipefs -a /dev/$partition3 &> /dev/null
    wipefs -a /dev/$partition &> /dev/null

    swap=$( free -m | grep "Mem" | awk '{ print $2 }' )
    (( ( swap / 2000 ) + 1 ))

    log.info "Creating a new partition table..."
    if [ "$uefi" = true ]
    then
        sgdisk -Z /dev/$partition &> /dev/null
        sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$partition &> /dev/null
        sgdisk -n 0:0:+${swap}G -t 0:8200 -c 0:"swap" /dev/$partition &> /dev/null
        sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$partition &> /dev/null
        sgdisk -p /dev/$partition &> /dev/null
    else
        [[ "$usb" == "n" ]] && additionnal_instructions="+${swap}G\nn\np\n3\n\n"
        printf "o\nn\np\n1\n\n+500M\nn\np\n2\n\n${additionnal_instructions}\nw\n" | fdisk /dev/$partition &> /dev/null
        fdisk -l /dev/$partition &> /dev/null
    fi

    log.info "Updating the partition table..."
    partprobe /dev/$partition > /dev/null

    log.info "Formatting the \"boot\" partition..."
    if [[ "$usb" == "n" ]]
    then
      [[ "$uefi" = true ]] && mkfs.fat -F32 /dev/$partition1 &> /dev/null || mkfs.ext2 -F /dev/$partition1 &> /dev/null
      
      log.ingo "Formatting the \"swap\" partition..."
      mkswap /dev/$partition2 &> /dev/null
      swapon /dev/$partition2 &> /dev/null
      
      log.info "Formatting the \"arch\" partition..."
      mkfs.ext4 -F /dev/$partition3 &> /dev/null
    else
      mkfs.ext4 -O "^has_journal" /dev/$partition1 &> /dev/null
      
      log.info "Formatting the \"arch\" partition..."
      mkfs.ext4 -O "^has_journal" /dev/$partition3 &> /dev/null
    fi

    log.info "Mounting \"/mnt\"..."
    mount /dev/$partition3 /mnt
    log.info "Creating \"/mnt/boot\"..."
    mkdir /mnt/boot
    log.info "Creating \"/mnt/home\"..."
    mkdir /mnt/home
    log.info "Mounting \"/mnt/boot\"..."
    mount /dev/$partition1 /mnt/boot
    log.info "Mounting \"/mnt/home\"..."
    mount /dev/$partition3 /mnt/home

    # Chapter III - Installation

    printf "\n    ---\n\n    Chapter III - Installation\n\n"

    if [[ "$mirror" == "y" ]]
    then
      log.info "Updating the mirror list..."
      cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
      sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup      
      rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
    fi

    log.info "Installing the operating system..."
    pacstrap /mnt base base-devel &> /dev/null

    # Chapter IV - Configuration

    printf "\n    ---\n\n    Chapter IV - Configuration\n\n"

    log.info "Generating the fstab file..."
    genfstab -U /mnt >> /mnt/etc/fstab

    log.info "Setting the time..."
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    arch-chroot /mnt hwclock --systohc --utc

    log.info "Setting the language..."
    arch-chroot /mnt sed -i '/'\#en_US.UTF-8'/s/^#//' /etc/locale.gen
    arch-chroot /mnt locale-gen > /dev/null
    arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf > /dev/null

    log.info "Creating the hostname..."
    arch-chroot /mnt echo $hostnm > /mnt/etc/hostname
    arch-chroot /mnt echo "127.0.1.1	$hostnm.localdomain     $hostnm" >> /mnt/etc/hosts
    
    log.info "Creating the user..."
    arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usernm
    arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
    arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/ a Defaults rootpw' /etc/sudoers 

    log.info "Setting user's password..."
    printf "$usertpw\n$userpw\n" | arch-chroot /mnt passwd $usernm

    log.info "Setting root's password..."
    printf "$rootpw\n$rootpw\n" | arch-chroot /mnt passwd

    log.info "Updating pacman's configuration"
    arch-chroot /mnt sed -i '/'multilib\]'/s/^#//' /etc/pacman.conf
    arch-chroot /mnt sed -i '/\[multilib\]/ a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
}

main 

exit 0

log.info "Updating the repositories..."
arch-chroot /mnt pacman -Sy
log.info "Installing the Intel microcode package..."
arch-chroot /mnt pacman -S --noconfirm intel-ucode &> /dev/null
log.info "Installing wifi packages..."
arch-chroot /mnt pacman -S --noconfirm iw wpa_supplicant &> /dev/null
log.info "Installing video drivers..."
arch-chroot /mnt pacman -S --noconfirm xf86-video-intel mesa &> /dev/null
log.info "Installing X..."
arch-chroot /mnt pacman -S --noconfirm xorg-server xorg-xinit &> /dev/null
log.info "Installing yay..."
arch-chroot /mnt pacman -S --noconfirm yay &> /dev/null

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

#!/bin/bash

echo -e "\n    Welcome.
\n  This script will guide you during this very painful installation of Arch Linux.
\n  Put your belt on, take a deep breath and please try not to panic."
read -p "\n  Press enter to continue"

echo -e "\n\n    Chapter I - Preparations\n"
echo -e "  Checking the internet connection..."
until ping -c 1 archlinux.org > /dev/null
do
  echo -e "\nPlug an ethernet cable"
  read -p "Press enter to continue"
  systemctl stop dhcpcd
  systemcll start dhcpcd
  sleep 5
  ping -c 1 archlinux.org > /dev/null
done

echo -e "  Updating the system clock..."
timedatectl set-ntp true

echo -e "\n\n    Chapter II - Partitions\n"
lsblk
read -p "  Enter the name of the disered path (Example : sda): " sd

echo -e "  Destroying the partition table..."
sgdisk -Z /dev/sdb > /dev/null
echo -e "  Formatting the \"boot\" partition..."
sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd > /dev/null
ram=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
echo -e "  Formatting the \"swap\" partition..."
sgdisk -n 0:0:+${ram}G -t 0:8200 -c 0:"swap" /dev/$sd > /dev/null
echo -e "  Formatting the \"arch\" partition..."
sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd > /dev/null
echo -e "  Updating the partition table..."
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

echo -e "  Installing the base packages (no worries, warnings are completely normal)..."
pacstrap /mnt base base-devel > /dev/null

echo -e "\n\n    Chapter IV - Configure the system\n"

echo -e "  Generating the fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "  Setting the time..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

echo -e "  Setting the language..."
arch-chroot /mnt sed -i '/'\#en_US.UTF-8'/s/^#//' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf

echo -e "  Creating the hostname..."
read -p "  Enter a hostname : " hostnm
arch-chroot /mnt echo $hostnm > /mnt/etc/hostname
arch-chroot /mnt echo "127.0.1.1	$hostnm.localdomain     $hostnm" >> /mnt/etc/hosts

echo -e "  Updating \"pacman.conf\"..."
arch-chroot /mnt sed -i '/'multilib\]'/s/^#//' /etc/pacman.conf
arch-chroot /mnt sed -i '/\[multilib\]/ a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
arch-chroot /mnt echo -e "[archlinuxfr]" >> /mnt/etc/pacman.conf
arch-chroot /mnt echo -e "SigLevel = Never" >> /mnt/etc/pacman.conf
arch-chroot /mnt echo -e "Server = http://repo.archlinux.fr/\$arch" >> /mnt/etc/pacman.conf
echo -e "  Updating Pacman..."
arch-chroot /mnt pacman -Sy > /dev/null
echo -e "  Installing Yaourt..."
arch-chroot /mnt pacman -S yaourt > /dev/null
echo -e "  Installing Bash-completion..."
arch-chroot /mnt pacman -S bash-completion > /dev/null
echo -e "  Installing wifi packages..."
arch-chroot /mnt pacman -S iw wpa_supplicant dialog > /dev/null
echo -e "  Installing the Intel microcode package..."
arch-chroot /mnt pacman -S intel-ucode > /dev/null

echo -e "  Enter root's password: "
arch-chroot /mnt passwd
read -p "Enter a username: " usr
echo -e "  Creating the user..."
arch-chroot /mnt useradd -m -g users -G wheel,storage,power -s /bin/bash $usr
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/s/^# //' /etc/sudoers
arch-chroot /mnt sed -i '/%wheel ALL=(ALL) ALL/ a Defaults rootpw' /etc/sudoers 
echo -e "  Enter the user's password: "
arch-chroot /mnt passwd $usr

echo -e "  Setting the boot loader..."
arch-chroot /mnt bootctl install > /dev/null
arch-chroot /mnt echo -e "title Arch Linux" > /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo -e "linux /vmlinuz-linux" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo -e "initrd /intel-ucode.img" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo -e "initrd /initramfs-linux.img" >> /mnt/boot/loader/entries/arch.conf
arch-chroot /mnt echo -e "options root=/dev/$sd3 pcie_aspm=force rw" >> /mnt/boot/loader/entries/arch.conf

read -p "\n\n  Done.\n\n  Press enter to continue"
umount -R /mnt
shutdown

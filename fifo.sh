#!/bin/bash

clear
echo -e "\n    Welcome.
  This script will guide you during this very painful installation of Arch Linux.
  Put your belt on, take a deep breath and please try not to panic.
  
  Caution: This script does NOT support dual boot and probably never will, just embrace Arch."
read -p "`echo -e "\n  "`Press enter to continue"


echo -e "\n\n    Chapter I - Preparations\n"

input() {
  value=$1
  value=${value,,}
  value=${value::1}
  while [[ "$value" != "y" && "$value" != "n" ]]
  do
    read -p "  Wrong answer `echo $'\n> '`" value
    value=${value,,}
    value=${value::1}
  done
  eval "$1=$value"
} 

echo "  Checking the internet connection..."
ping -c 1 archlinux.org &> /dev/null
if [ $? != 0 ]
then
  read -p "  Do you want to use wifi (Y/n) ? `echo $'\n> '`" wifi
  input $wifi
  while [ "$wifi" = "y" ]
  do
    wifi-menu
    if [ $? != 0 ]
    then
      read -p "  Do you want to try again (Y/n)?  `echo $'\n> '`" wifi
      input $wifi
    else
      wifi="n"
    fi
  done
fi
until ping -c 1 archlinux.org &> /dev/null
do
  echo -e "  Plug an ethernet cable"
  read -p "  Press enter to continue"
  systemctl stop dhcpcd
  systemctl start dhcpcd
  sleep 5
done

echo "  Checking if booted as bios or uefi..."
ls /sys/firmware/efi/efivars &> /dev/null
if [ $? = 0 ]
then
  uefi=true
else
  uefi=false
fi

echo "  Updating the system clock..."
timedatectl set-ntp true


echo -e "\n\n    Chapter II - Partitions\n"

lsblk
read -p "  Enter the name of the disered path (Example : sda) `echo $'\n> '`" sd
sd=${sd,,}
while ! [ `lsblk | awk '$6 == "disk"' | awk '{print $1}' | grep -x $sd` ]
do
  read -p "  Wrong answer `echo $'\n> '`" sd
  sd=${sd,,}
done
between=`lsblk | awk '$6 == "part"' | awk '{print $1}' | grep $sd | head -1 | sed "s/^.*$sd//" | sed 's/.$//'`
sd1=$sd$between\1
sd2=$sd$between\2
sd3=$sd$between\3

echo "  Destroying the partition table..."

wipefs --all --force /dev/$sd
swap=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
wipefs -a /dev/$sd1 &> /dev/null
wipefs -a /dev/$sd2 &> /dev/null
wipefs -a /dev/$sd3 &> /dev/null
wipefs -a /dev/$sd &> /dev/null
echo "test"
if [ "$uefi" = true ]
then
  sgdisk -Z /dev/$sd > /dev/null
  echo -e "  Creating the \"boot\" partition..."
  sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd &> /dev/null
  echo -e "  Creating the \"swap\" partition..."
  sgdisk -n 0:0:+${swap}G -t 0:8200 -c 0:"swap" /dev/$sd &> /dev/null
  echo -e "  Creating the \"arch\" partition..."
  sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd &> /dev/null
  sgdisk -p /dev/$sd > /dev/null
else
  echo "o
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


w" | fdisk /dev/$sd > /dev/null
  echo "test2"
  fdisk -l /dev/$sd > /dev/null
  echo "test3"
fi
echo "  Updating the partition table..."
partprobe /dev/$sd > /dev/null

echo -e "  Formatting the \"boot\" partition..."
if [ "$uefi" = true ]
then
  mkfs.fat -F32 /dev/$sd1 &> /dev/null
else
  mkfs.ext2 -F /dev/$sd1 &> /dev/null
fi
# mkfs.fat -F32 /dev/$sd1 &> /dev/null
echo -e "  Formatting the \"swap\" partition..."
mkswap /dev/$sd2 &> /dev/null
swapon /dev/$sd2 &> /dev/null
echo -e "  Formatting the \"arch\" partition..."
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
echo "  Installing the network manager..."
arch-chroot /mnt pacman -Syy --noconfirm networkmanager &> /dev/null
arch-chroot /mnt systemctl enable NetworkManager &> /dev/null
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
  arch-chroot /mnt pacman -Syy --noconfirm grub &> /dev/null
  echo -e "  Installing Grub..."
  arch-chroot /mnt grub-install --target=i386-pc /dev/$sd
  if [ $? != 0 ]
  then
    echo -e "  Something went wrong, reinstalling Grub..."
    arch-chroot /mnt grub-install --no-floppy --recheck --target=i386-pc /dev/$sd
  fi
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -e "\n\n  Done.\n\n"
read -p "  Press enter to continue"
umount -R /mnt
shutdown -h now

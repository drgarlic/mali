#!/bin/bash

echo -e "\n  Welcome.
\nThis script will guide you during this very painful installation of Arch Linux.
\nPut your belt on, take a deep breath and please try not to panic."
read -p "Press enter to continue"

echo -e "\n\n  Chapter I - Preparations\n"
echo -e "Checking the internet connection"
until ping -c 1 archlinux.org > /dev/null
do
  echo -e "\nPlug an ethernet cable"
  read -p "Press enter to continue"
  systemctl stop dhcpcd
  systemcll start dhcpcd
  sleep 5
  ping -c 1 archlinux.org > /dev/null
done

echo -e "\nUpdating the system clock"
timedatectl set-ntp true

echo -e "\n\n  Chapter II - Partitions\n"
lsblk
read -p "Enter the name of the disered path (Example : sda): " sd

echo -e "Destroying the partition table"
sgdisk -Z /dev/sdb > /dev/null
echo -e "Formatting the \"boot\" partition"
sgdisk -n 0:0:+500M -t 0:ef00 -c 0:"boot" /dev/$sd > /dev/null
ram=`expr \`free -m | grep -oP '\d+' | head -n 1\` / 2000 + 1`
echo -e "Formatting the \"swap\" partition"
sgdisk -n 0:0:+${ram}G -t 0:8200 -c 0:"swap" /dev/$sd > /dev/null
echo -e "Formatting the \"arch\" partition"
sgdisk -n 0:0:0 -t 0:8300 -c 0:"arch" /dev/$sd > /dev/null
echo -e "Updating the partition table"
sgdisk -p /dev/$sd > /dev/null
partprobe /dev/$sd > /dev/null
fdisk -l /dev/$sd > /dev/null

sd1=$sd\1
echo -e "Formatting the \"boot\" partition"
mkfs.fat -F32 /dev/$sd1 > /dev/null
echo -e "Formatting the \"swap\" partition"
sd2=$sd\2
mkswap /dev/$sd2 > /dev/null
swapon /dev/$sd2
echo -e "Formatting the \"arch\" partition"
sd3=$sd\3
mkfs.ext4 -F /dev/$sd3 > /dev/null

echo -e "Mountting \"/mnt\""
mount /dev/$sd3 /mnt
echo -e "Creatting \"/mnt/boot\""
mkdir /mnt/boot
echo -e "Creatting \"/mnt/home\""
mkdir /mnt/home
echo -e "Mountting \"/mnt/boot\""
mount /dev/$sd1 /mnt/boot
echo -e "Mountting \"/mnt/home\""
mount /dev/$sd3 /mnt/home

echo -e "\n\n  Chapter III - Installation\n"

echo -e "Installing the base packages (no worries, warnings are completely normal)"
pacstrap /mnt base base-devel > /dev/null

echo -e "\n\n  Chapter IV - Configure the system\n"

echo -e "\nFstab"
genfstab -U /mnt >> /mnt/etc/fstab

#!/bin/bash

echo -e "\n  Welcome.
\n  This script will guide you during this very painful installation of Arch Linux.
\n  Put your belt on, take a deep breath and please try not to panic."

read -p "\n  Press enter to continue."

until ping -c 1 archlinux.org > /dev/null
do
  echo -e "\n  You fool... You forgot to plug the ethernet cable."
  read -p "\n  Press enter if you plugged it."
  systemctl stop dhcpcd
  systemcll start dhcpcd
  sleep 5
  ping -c 1 archlinux.org > /dev/null
done

timedatectl set-ntp true

echo -e "\n\n  Chapter I - Partitions"
lsblk
read -p "\n  Enter the name of your interested path (Example : sda) : " sd

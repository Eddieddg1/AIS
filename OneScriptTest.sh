#!/bin/bash

set -e

timedatectl
echo "Available disks:"
fdisk -l | grep "Disk /dev/"
read -p "Enter the disk to partition (e.g., sda, nvme0n1): " DISK

if [[ $DISK == nvme* ]]; then
    PART_SUFFIX="p"
else
    PART_SUFFIX=""
fi

read -p "Enter swap size in GB (4 or more for swap, less for no swap): " SWAP

export DISK PART_SUFFIX SWAP

(
echo g
echo n
echo
echo
echo +1G
echo y
echo t
echo EFI System
if [[ $SWAP -ge 4 ]]; then
    echo n
    echo
    echo
    echo +${SWAP}G
fi
echo n
echo
echo
echo
echo w
) | fdisk /dev/$DISK

mkfs.fat -F 32 /dev/${DISK}${PART_SUFFIX}1
if [[ $SWAP -ge 4 ]]; then
    mkswap /dev/${DISK}${PART_SUFFIX}2
    swapon /dev/${DISK}${PART_SUFFIX}2
fi
mkfs.ext4 /dev/${DISK}${PART_SUFFIX}3

mount /dev/${DISK}${PART_SUFFIX}3 /mnt
mkdir -p /mnt/boot
mount /dev/${DISK}${PART_SUFFIX}1 /mnt/boot

echo "pacstrap -K /mnt base linux linux-firmware fastfetch htop nano sddm networkmanager systemctl"
read -p "Do you want to add any packages?: " PAC
pacstrap -K /mnt --confirm base base-devel linux linux-firmware fastfetch htop nano sddm networkmanager systemctl ${PAC}

genfstab -U /mnt >> /mnt/etc/fstab

cp ./Arch_autoInstall.sh /mnt
chmod +x /mnt/Arch_autoInstall.sh
arch-chroot /mnt /bin/bash -c "./Arch_autoInstall.sh"

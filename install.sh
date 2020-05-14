#!/usr/bin/bash

DISK=sda
PASSWORD="mypassword"
HOSTNAME="MYHOSTNAME"

# Update the system clock
timedatectl set-ntp true

# Partition the disks
parted -s /dev/"$DISK" mktable gpt
parted -s /dev/"$DISK" mkpart primary fat32 1MiB 1025MiB
parted -s /dev/"$DISK" set 1 boot on
parted -s /dev/"$DISK" mkpart primary 1025MiB 100%

# Format the partitions
mkfs.vfat /dev/"$DISK"1
mkfs.xfs /dev/"$DISK"2

# Mount the file systems
mount /dev/"$DISK"2 /mnt
mkdir /mnt/boot
mount /dev/"$DISK"1 /mnt/boot

# Select the mirrors
pacman -Syy pacman-contrib --noconfirm
curl -s 'https://www.archlinux.org/mirrorlist/country=GB&protocol=https&use_mirror_status=on' | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -

# Install essential packages
pacstrap /mnt base linux dracut

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy Chroot Install
sed -i -e "s/NO_HOSTNAME/$HOSTNAME/g" /etc/hosts
cp chroot_install.sh /mnt/chroot_install.sh

# Chroot
arch-chroot /mnt ./chroot_install.sh
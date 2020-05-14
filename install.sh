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

UUID_DISK1=$(blkid /dev/"$DISK"2 -s UUID -o value)

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

# Chroot
arch-chroot /mnt <<'EOF'

## Time zone
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc

## Localization
sed -i -e 's/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

## Network Configuration
echo 'HOSTNAME' > /etc/hostname
echo '127.0.0.1		localhost' > /etc/hosts
echo '::1			localhost' >> /etc/hosts
echo '127.0.1.1 	HOSTNAME.localdomain		HOSTNAME' >> /etc/hosts
sed -i -e "s/HOSTNAME/$HOSTNAME/g" /etc/hostname
sed -i -e "s/HOSTNAME/$HOSTNAME/g" /etc/hosts

## Initramfs
dracut -H -f --hostonly-cmdline /boot/initramfs-linux.img

## Root password
passwd

## Boot Loader
bootctl --path=/boot install
echo 'default       arch' > /boot/loader/loader.conf
echo 'editor        no' >> /boot/loader/loader.conf
echo 'auto-entries  no' >> /boot/loader/loader.conf
echo 'auto-firmware no' >> /boot/loader/loader.conf
echo 'console-mode  max' >> /boot/loader/loader.conf
echo 'title     Arch Linux' > /boot/loader/entries/arch.conf
echo 'linux     /vmlinuz-linux' >> /boot/loader/entries/arch.conf
echo 'initrd    /initramfs-linux.img' >> /boot/loader/entries/arch.conf
echo "options   root=$UUID_DISK1" >> /boot/loader/entries/arch.conf

EOF
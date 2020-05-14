#!/usr/bin/bash

HOSTNAME="NO_HOSTNAME"
UUID_DISK1=$(blkid /dev/"$DISK"2 -s UUID -o value)

# Time zone
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc

# Localization
sed -i -e 's/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Network Configuration
echo 'HOSTNAME' > /etc/hostname
echo '127.0.0.1		localhost' > /etc/hosts
echo '::1			localhost' >> /etc/hosts
echo '127.0.1.1 	HOSTNAME.localdomain		HOSTNAME' >> /etc/hosts
sed -i -e "s/HOSTNAME/$HOSTNAME/g" /etc/hostname
sed -i -e "s/HOSTNAME/$HOSTNAME/g" /etc/hosts

# Initramfs
dracut -H -f --hostonly-cmdline /boot/initramfs-linux.img

# Boot Loader
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

# Root password
passwd
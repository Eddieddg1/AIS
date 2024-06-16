read -p "Enter Region/City for timezone (e.g., Europe/Berlin): " TIMEZONE
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

locale-gen
read -p "Please select language. en_US.UTF-8: " LANG
if [[ -z "$LANG" ]]; then
    LANG="en_US.UTF-8"
fi
echo "LANG=$LANG" > /etc/locale.conf
echo "$LANG UTF-8" > /etc/locale.gen
locale-gen

read -p "Please select keyboard layout. sv-latin1: " KEYMAP
if [[ -z "$KEYMAP" ]]; then
    KEYMAP="sv-latin1"
fi
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

mkinitcpio -P

echo "Enter root password"
passwd

echo "Boot loaders: (~)EFISTUB, (X)Unified kernel image, (~)GRUB, (X)Limine, (X)rEFInd, (X)Syslinux, (X)systemd-boot"
echo "(X) = Not currently supported, (O) = Supported, (~) Work In Progress"
read -p "Please make sure to spell it correctly: " boot
case "$boot" in
    "EFISTUB")
        pacman -S --noconfirm efibootmgr
        umount /dev/${DISK}${PART_SUFFIX}1
        mkdir -p /boot/efi
        mount /dev/${DISK}${PART_SUFFIX}1 /boot/efi
        efibootmgr --create --disk /dev/${DISK} --part 1 --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=/dev/${DISK}${PART_SUFFIX}3 rw initrd=\initramfs-linux.img'
        ;;
#    "Unified kernel image")
#        umount /dev/${DISK}${PART_SUFFIX}1
#        mount --mkdir /dev/${DISK}${PART_SUFFIX}1 /boot/efi
#        ;;
    "GRUB")
        pacman -S --noconfirm grub efibootmgr
        umount /dev/${DISK}${PART_SUFFIX}1
        mkdir -p /boot/efi
        mount /dev/${DISK}${PART_SUFFIX}1 /boot/efi
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
        grub-mkconfig -o /boot/grub/grub.cfg
        ;;
#    "Limine")
#        sudo pacman -S limine
#        ;;
#    "rEFInd")
#        sudo pacman -S refind
#        ;;
#    "Syslinux")
#        sudo pacman -S syslinux
#        syslinux-install_update -i -a -m
#        ;;
#    "systemd-boot")
#        sudo pacman -S bootctl
#        bootctl install
#        ;;
    *)
        echo "Boot loader '$boot' not recognized or not supported."
        exit 1
        ;;
esac

read -p "Do you want Awesome and SDDM? (O for awesome): " AWESOME
if [[ $AWESOME == O* ]]; then
    pacman -S awesome
fi

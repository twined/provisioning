#!/bin/sh

# 1. Create 3 new disks.
#    a) boot - 256mb
#    b) swap - 512mb
#    c) root - remaining
# 2. Create a config profile using the new disk images, (sda=boot, sdb=root, sdc=swap) GRUB2 as kernel and no Filesystem/Boot helpers
# 3. Boot into rescue mode with the new disk images (sda=boot, sdb=root, sdc=swap).
# 4. update-ca-certificates && wget https://raw.githubusercontent.com/twined/provisioning/master/alpine/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh

set -e

KEYMAP="${KEYMAP:-'us us'}"
HOST=${HOST:-opal}
INTERFACES="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
  hostname $HOST
"

FEATURES="ata ide scsi virtio base ext4"
MODULES="ext4"

REL=${REL:-3.5}
MIRROR=${MIRROR:-http://nl.alpinelinux.org/alpine}
REPO=$MIRROR/v$REL/main
APKV=${APKV:-2.6.8-r2}

ARCH=$(uname -m)

umount /dev/sda || /bin/true
umount /dev/sdb || /bin/true
mkfs.ext4 -L boot /dev/sda
mkfs.ext4 -L root /dev/sdb
mkswap /dev/sdc

mount /dev/sdb /mnt
mkdir /mnt/boot
mount /dev/sda /mnt/boot

curl -s $MIRROR/v$REL/main/$ARCH/apk-tools-static-${APKV}.apk | tar xz
./sbin/apk.static --repository $REPO --update-cache --allow-untrusted \
  --root /mnt --initdb add alpine-base

cat <<EOF > /mnt/etc/fstab
/dev/sdb  /       ext4        defaults,noatime    0   0
/dev/sda  /boot   ext4        defaults,noatime    0   1
/dev/sdc  swap    swap        defaults            0   0
EOF
echo $REPO > /mnt/etc/apk/repositories

sed -i '/^tty[0-9]:/d' /mnt/etc/inittab
echo 'ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100' >> /mnt/etc/inittab

mkdir -p /mnt/boot/grub
cat <<EOF > /mnt/boot/grub/grub.cfg
set root=(hd0)
set default="Alpine Linux"
set timeout=0

menuentry "Alpine Linux" {
    linux /vmlinuz-grsec root=/dev/sdb modules=sd-mod,usb-storage,ext4 console=ttyS0 quiet
    initrd /initramfs-grsec
}
EOF

cp /etc/resolv.conf /mnt/etc

echo ttyS0 >> /mnt/etc/securetty

mount --bind /proc /mnt/proc
mount --bind /dev /mnt/dev

chroot /mnt /bin/sh<<CHROOT
apk update --quiet

setup-hostname -n $HOST
printf "$INTERFACES" | setup-interfaces -i

rc-update add networking boot
rc-update add urandom boot
rc-update add crond

apk add openssh
rc-update add sshd default

mkdir /etc/mkinitfs
echo features=\""$FEATURES"\" > /etc/mkinitfs/mkinitfs.conf

apk add linux-grsec

CHROOT

umount /mnt/proc
umount /mnt/dev
umount /mnt/boot
umount /mnt

echo "== Bootstrap finished. Type reboot to reboot system"

# reboot

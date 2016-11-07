#!/bin/sh

# 1. Create 3 new disks.
#    a) boot - 256mb
#    b) swap - 512mb
#    c) root - remaining
# 2. Create a config profile using the new disk images, (sda=boot, sdb=root, sdc=swap) GRUB2 and no Filesystem/Boot helpers
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
BOOT_FS=${ROOT_FS:-ext4}
ROOT_FS=${ROOT_FS:-ext4}

FEATURES="ata ide scsi virtio base $ROOT_FS"
MODULES="$ROOT_FS"

REL=${REL:-3.4}
MIRROR=${MIRROR:-http://nl.alpinelinux.org/alpine}
REPO=$MIRROR/v$REL/main
APKV=${APKV:-2.6.7-r0}
BOOT_DEV=${BOOT_DEV:-/dev/sda}
ROOT_DEV=${ROOT_DEV:-/dev/sdb}
SWAP_DEV=${SWAP_DEV:-/dev/sdc}

ROOT=${ROOT:-/mnt}
ARCH=$(uname -m)

umount $BOOT_DEV || /bin/true
umount $ROOT_DEV || /bin/true
mkfs.$BOOT_FS -L boot $BOOT_DEV
mkfs.$ROOT_FS -L root $ROOT_DEV
mkswap $SWAP_DEV

mount $ROOT_DEV $ROOT
mkdir $ROOT/boot
mount $BOOT_DEV $ROOT/boot

curl -s $MIRROR/v$REL/main/$ARCH/apk-tools-static-${APKV}.apk | tar xz
./sbin/apk.static --repository $REPO --update-cache --allow-untrusted \
  --root $ROOT --initdb add alpine-base

cat <<EOF > $ROOT/etc/fstab
$ROOT_DEV  /       $ROOT_FS    defaults,noatime    0   0
$BOOT_DEV  /boot   $BOOT_FS    defaults,noatime    0   1
$SWAP_DEV  swap    swap        defaults            0   0
EOF
echo $REPO > $ROOT/etc/apk/repositories

sed -i '/^tty[0-9]:/d' $ROOT/etc/inittab
echo 'ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100' >> $ROOT/etc/inittab

mkdir -p $ROOT/boot/grub
cat <<EOF > $ROOT/boot/grub/grub.cfg
set root=(hd0)
set default="Alpine Linux"
set timeout=0

menuentry "Alpine Linux" {
    linux /vmlinuz-grsec root=/dev/sdb modules=sd-mod,usb-storage,ext4 console=ttyS0 quiet
    initrd /initramfs-grsec
}
EOF

cp /etc/resolv.conf $ROOT/etc

echo ttyS0 >> $ROOT/etc/securetty

mount --bind /proc $ROOT/proc
# mount --bind /dev $ROOT/dev

chroot $ROOT /bin/sh<<CHROOT
apk update --quiet

setup-hostname -n $HOST
printf "$INTERFACES" | setup-interfaces -i

rc-update -q add networking boot
rc-update -q add urandom boot
rc-update -q add crond

apk add --quiet openssh
rc-update -q add sshd default

mkdir /etc/mkinitfs
echo features=\""$FEATURES"\" > /etc/mkinitfs/mkinitfs.conf

apk add --quiet linux-grsec

CHROOT

umount $ROOT/proc
umount $ROOT/boot
umount $ROOT

echo "== Bootstrap finished. Rebooting now."

reboot

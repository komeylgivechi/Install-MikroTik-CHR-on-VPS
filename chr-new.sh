#!/bin/bash -e

echo
echo "Downloading MikroTik CHR Image..."
sleep 3
wget https://download.mikrotik.com/routeros/7.11.2/chr-7.11.2.img.zip -O chr.img.zip

echo "Extracting Image..."
unzip -p chr.img.zip > chr.img

STORAGE=$(lsblk -dn -o NAME | head -n 1)
echo "STORAGE is $STORAGE"

ETH=$(ip route show default | awk '{print $5}')
echo "ETH is $ETH"

ADDRESS=$(ip addr show $ETH | grep global | awk '{print $2}' | head -n 1)
echo "ADDRESS is $ADDRESS"

GATEWAY=$(ip route show default | awk '{print $3}')
echo "GATEWAY is $GATEWAY"

sleep 5

echo "Writing CHR image to disk..."
dd if=chr.img of=/dev/$STORAGE bs=4M oflag=sync

# Mount CHR partition and add autorun script
echo "Mounting CHR disk and adding autorun script..."
mkdir -p /mnt/chr
mount /dev/${STORAGE}1 /mnt/chr || { echo "Failed to mount CHR disk"; exit 1; }

# Create MikroTik autorun script to change admin password
cat <<EOF > /mnt/chr/rw/autorun.scr
/user set admin password="P@ssw0rd@"
EOF

# Unmount before reboot
echo "Unmounting and syncing..."
umount /mnt/chr
sync

echo "Installation complete. Rebooting..."
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

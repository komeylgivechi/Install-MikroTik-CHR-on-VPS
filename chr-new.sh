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

# Wait for the disk to be recognized
sleep 10

# Find the first partition of the CHR disk
PARTITION="/dev/${STORAGE}1/"
echo "Partition is $PARTITION"

# Check and repair the filesystem if needed
echo "Checking filesystem..."
fsck -y $PARTITION || echo "Filesystem check completed."

# Try mounting the CHR partition
echo "Mounting CHR disk..."
mount $PARTITION /mnt/ || { echo "Failed to mount CHR disk"; exit 1; }

# Ensure the mount point exists
mkdir -p /mnt/chr || echo "/mnt/chr already exists."

# Create MikroTik autorun script to change admin password
echo "Creating autorun script..."
cat <<EOF > /mnt/chr/rw/autorun.scr
/user set admin password="P@ssw0rd@"
EOF

# Ensure changes are written
sync

# Unmount before reboot
echo "Unmounting and syncing..."
umount /mnt/chr
sync

echo "Installation complete. Rebooting..."
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger

#!/bin/bash
#set -e

UBUNTU_FILE=Orangepi5_1.1.8_ubuntu_jammy_server_linux6.1.43
UBUNTU_IMAGE=$UBUNTU_FILE.img
SSD_ID=nvme0n1
SSD_MOUNT=nvme0n1p2
SERVER_IP=192.168.3.49
SERVER_HOSTNAME=sbc-server-3

SERVER_IP=192.168.3.100

## SSH into the machine (rm ~/.ssh/known_hosts)
ssh orangepi@$SERVER_IP

# Files must be copied into SD Card
cd cluster

## Unzip de ubuntu image if compressed
7z x $UBUNTU_FILE.7z

# Removing and flashing Ubuntu image into SSD
# echo "Removing and flashing Ubuntu image into SSD"
sudo dd bs=1M if=/dev/zero of=/dev/$SSD_ID count=2000 status=progress && sudo sync
sudo dd bs=1M if=$UBUNTU_IMAGE of=/dev/$SSD_ID status=progress && sudo sync
sudo fix_mmc_ssd.sh
# echo "Ubuntu has been successfully flashed"

# Mount the NVME
# echo "Mounting the SSD boot and replace DietPi init"
sudo mount /dev/$SSD_MOUNT /mnt/

# Copy the ssh keys and network configuration (nmtui)
mkdir /mnt/home/orangepi/.ssh
cp $HOME/.ssh/server_key.pub /mnt/home/orangepi/.ssh/server_key.pub

# Copy Network Profile shoulbe and set owned by root and be readably only by root - otherwise NetworkManager will ignore it.
sudo cp "default.nmconnection" /mnt/etc/NetworkManager/system-connections
sudo chmod -R 600 /mnt/etc/NetworkManager/system-connections/default.nmconnection
sudo chown -R root:root /mnt/etc/NetworkManager/system-connections/default.nmconnection

# sudo hostnamectl set-hostname sbc-server-1
echo $SERVER_HOSTNAME | sudo tee /mnt/etc/hostname > /dev/null 2>&1
CURRENT_HOSTNAME=$(cat /mnt/etc/hostname)

if [ $SERVER_HOSTNAME = $CURRENT_HOSTNAME ]; then
    echo "Name already set"
else
    echo "Setting Name" $SERVER_HOSTNAME
    echo $SERVER_HOSTNAME > /mnt/etc/hostname
    sed -i "/127.0.1.1/s/$CURRENT_HOSTNAME/$SERVER_HOSTNAME/" /mnt/etc/hosts
fi

# WARNING: Disable password login https://www.cyberciti.biz/faq/how-to-disable-ssh-password-login-on-linux/

sudo umount /mnt/ && sudo sync
# echo "Ubunut init replaced"

sudo poweroff

# Post-installation
sudo -S apt-get remove needrestart -y && sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install net-tools iputils-ping python3-pip -y
sudo reboot

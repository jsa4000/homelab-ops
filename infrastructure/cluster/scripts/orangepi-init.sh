#!/bin/bash
#set -e

# Installation process (NVME only):
# 1. Download the Ubuntu Orange Pi image from official web site (Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z)
# 2. Flash a SD Card using balenaEcher using previous image.
# 3. Plug the SD Card into the device and power on.
# 4. SSH into the device, use the Router to obtain the IP Adress of the device (ssh orangepi@192.168.3.49 (orangepi/orangepi)).
# 5. Copy the scripts to the SD card and ssh public key (using scp or sftp)
# 6. Run this script (source ./scripts/orangepi-init.sh)

# Notes:
# - The SD Card can be reused to configure multiple devices
# - The first time a device is configure this script should be run, because the SPI Flash loader.

# How To use it:
# > source ./scripts/orangepi-init.sh

LOADER_PATH=/usr/lib/linux-u-boot-legacy-orangepi5_1.1.8_arm64/rkspi_loader.img
SPI_FLASH=mtdblock0
YQ_VESRION=v4.40.5
YQ_BINARY=yq_linux_arm64
YQ_URL=https://github.com/mikefarah/yq/releases/download/$YQ_VESRION/$YQ_BINARY.tar.gz

echo "------------------------------------------------------------"
echo "Initialization Script for OrangePi"
echo "------------------------------------------------------------"
echo

echo "Updating dependencies"
sudo apt update && sudo apt upgrade -y

echo "Installing common tools"
sudo apt install p7zip-full gettext-base xz-utils net-tools git -y
wget $YQ_URL -O - | tar xz && sudo mv $YQ_BINARY /usr/bin/yq

printf "Do you want to install the SPI loader? (y/n)"
read -r KEY_INPUT </dev/tty
if [ "$KEY_INPUT" = "y" ]; then

    echo "Installing the loader into SPI Flash"
    sudo dd if=/dev/zero of=/dev/$SPI_FLASH bs=1M count=1 && sudo sync
    sudo dd if=$LOADER_PATH of=/dev/$SPI_FLASH conv=notrunc && sudo sync
    echo "SPI loader successfully installed"

fi

echo DONE!

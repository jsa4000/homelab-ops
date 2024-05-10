#!/bin/bash
#set -e

# Installation process (NVME only):
# 1. Prepare the SD card with the Ubuntu image (ubuntu-24.04-preinstalled-server-arm64-orangepi-5.img.xz)
# 2. Remove all the data from SDD or destination storage.
# 3. Copy the image to the SDD or block storage (using 'dd' or any other method)
# 4. Copy the scripts to the SD card and ssh public key (using scp or sftp)
# 5. Run this script for a specific server: sbc-server-1, sbc-server-2, etc.. (i.e 'source ./scripts/cloud-init.sh sbc-server-1')
# 7.  Shutdown the device (sudo poweroff) and remove the SD card.

# How To use it:
# > source ./scripts/cloud-init.sh sbc-server-1
# > source ./scripts/cloud-init.sh sbc-server-1 ./config/servers.yaml
# > source ./scripts/cloud-init.sh $SERVER_NAME $CONFIG_FILE

SERVER_NAME=${1:-sbc-server-1}
CONFIG_FILE=${2:-./config/servers.yaml}

UBUNTU_IMAGE_PATH=.
#UBUNTU_IMAGE_NAME=ubuntu-24.04-preinstalled-server-arm64-orangepi-5
UBUNTU_IMAGE_NAME=ubuntu-22.04.3-preinstalled-server-arm64-orangepi-5
UBUNTU_IMAGE_FILE=$UBUNTU_IMAGE_PATH/$UBUNTU_IMAGE_NAME.img
UBUNTU_IMAGE_COMPRESSED=$UBUNTU_IMAGE_PATH/$UBUNTU_IMAGE_NAME.img.xz
#IMAGE_VESRION=2.0.0
IMAGE_VESRION=1.33
IMAGE_URL=https://github.com/Joshua-Riek/ubuntu-rockchip/releases/download/v$IMAGE_VESRION/$UBUNTU_IMAGE_COMPRESSED
USER_TEMPLATE_FILE=./config/templates/cloud-init/user-data.template
NETWORK_TEMPLATE_FILE=./config/templates/cloud-init/network-config.template
METADATA_TEMPLATE_FILE=./config/templates/cloud-init/meta-data.template
USER_FILE=user-data
NETWORK_FILE=network-config
METADATA_FILE=meta-data
USER_NAME=ubuntu
SSD_ID=nvme0n1
SSD_MOUNT=nvme0n1p1

echo "------------------------------------------------------------"
echo "Initialization Script for Ubuntu"
echo "------------------------------------------------------------"
echo

yq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: yq tool has been not found."
    return 1
fi

envsubst --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: envsubst tool has been not found."
    return 1
fi

7z --help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: 7zip tool has been not found."
    return 1
fi

if ! [ -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file does not exist: $CONFIG_FILE"
    return 1
fi


if ! [ -f "$UBUNTU_IMAGE_FILE" ]; then

    printf "Do you want to download the Ubuntu image? (y/n)"
    read -r KEY_INPUT </dev/tty

    if [ "$KEY_INPUT" = "y" ]; then

        wget $IMAGE_URL
        unxz $UBUNTU_IMAGE_COMPRESSED

    fi
fi

if [ -f "$UBUNTU_IMAGE_FILE" ]; then

    printf "Do you want to flash the Ubuntu image into SSD NVME drive? (y/n)"
    read -r KEY_INPUT </dev/tty

    if [ "$KEY_INPUT" = "y" ]; then

        echo "Removing and flashing Ubuntu image into SSD"
        sudo dd bs=1M if=/dev/zero of=/dev/$SSD_ID count=2000 status=progress && sudo sync
        sudo dd bs=1M if=$UBUNTU_IMAGE_FILE of=/dev/$SSD_ID status=progress && sudo sync
        sudo fix_mmc_ssd.sh
        echo "Ubuntu has been successfully flashed"

    fi

fi

export SERVER_PATH=.servers.$SERVER_NAME
export SERVER_INFO=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH))' $CONFIG_FILE)

if [ $? -ne 0 ] || [[ -z $SERVER_INFO ]]; then
    echo "ERROR: Parsing YAML file: $CONFIG_FILE"
    return 1
fi

export SERVER_HOSTNAME=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .hostname' $CONFIG_FILE)
export SERVER_IP=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .ip' $CONFIG_FILE)
export SERVER_MASK=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .mask' $CONFIG_FILE)
export SERVER_GATEWAY=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .gateway' $CONFIG_FILE)
export SERVER_DNS=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .dns' $CONFIG_FILE)
export SERVER_MAC=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .mac' $CONFIG_FILE)
export SSH_PUBKEY_FILE=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .ssh-key' $CONFIG_FILE)
export SERVER_USER=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .user' $CONFIG_FILE)

#export NETWORK_IFACE=end1
export NETWORK_IFACE=eth0
export NETWORK_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')

if ! [ -f "$SSH_PUBKEY_FILE" ]; then
    echo "ERROR: SSH Public key does not exist: $SSH_PUBKEY_FILE"
    return 1
fi

export SERVER_SSH_PUBKEY=$(cat "$SSH_PUBKEY_FILE")

echo "Server Info to be configured:"
echo
echo "  hostname: $SERVER_HOSTNAME"
echo "  ip:       $SERVER_IP"
echo "  mask:     $SERVER_MASK"
echo "  gateway:  $SERVER_GATEWAY"
echo "  dns:      $SERVER_DNS"
echo "  ssh:      $SERVER_SSH_PUBKEY"
echo "  user:     $SERVER_USER"

envsubst < $NETWORK_TEMPLATE_FILE > $NETWORK_FILE

envsubst < $USER_TEMPLATE_FILE > $USER_FILE
envsubst < $NETWORK_TEMPLATE_FILE > $NETWORK_FILE
envsubst < $METADATA_TEMPLATE_FILE > $METADATA_FILE

printf "Do you want to overwrite the default configuration? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then

    echo "Mounting the SSD boot and replace Ubuntu config"
    sudo mount /dev/$SSD_MOUNT /mnt/

    cat $USER_FILE | sudo tee /mnt/$USER_FILE > /dev/null 2>&1
    cat $NETWORK_FILE | sudo tee /mnt/$NETWORK_FILE > /dev/null 2>&1
    cat $METADATA_FILE | sudo tee /mnt/$METADATA_FILE > /dev/null 2>&1

    sudo umount /mnt/ && sudo sync
    echo "Ubuntu config replaced"

fi

printf "Do you want to power off the device? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then
   sudo poweroff
fi

echo DONE!

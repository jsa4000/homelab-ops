#!/bin/bash
#set -e

# Installation process (NVME only):
# 1. Prepare the SD card with the DietPI image (DietPi_OrangePi5-ARMv8-Bookworm.img.xz)
# 2. Remove all the data from SDD or destination storage.
# 3. Copy the image to the SDD or block storage (using 'dd' or any other method)
# 4. Copy the scripts to the SD card and ssh public key (using scp or sftp)
# 5. Run this script for a specific server: sbc-server-1, sbc-server-2, etc.. (i.e 'source ./scripts/dietpi-init.sh sbc-server-1')
# 6. Check the configuration set at '/mnt/dietpi.txt'
# 7.  Shutdown the device (sudo poweroff) and remove the SD card.

# How To use it:
# > source ./scripts/dietpi-init.sh sbc-server-1
# > source ./scripts/dietpi-init.sh sbc-server-1 ./config/servers.yaml ./dietpi.txt
# > source ./scripts/dietpi-init.sh $SERVER_NAME $CONFIG_FILE $OUTPUT_FILE
#

SERVER_NAME=${1:-sbc-server-1}
CONFIG_FILE=${2:-./config/servers.yaml}
OUTPUT_FILE=${3:-./dietpi.txt}

TEMPLATE_FILE=./config/templates/dietpi/dietpi.template.txt
DIETPI_IMAGE=DietPi_OrangePi5-ARMv8-Bookworm.img
DIETPI_URL=https://dietpi.com/downloads/images/$DIETPI_IMAGE.xz
DIETPI_FILE=dietpi.txt
SSD_ID=nvme0n1
SSD_MOUNT=nvme0n1p2

echo "------------------------------------------------------------"
echo "Initialization Script for DietPi"
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

if ! [ -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file does not exist: $CONFIG_FILE"
    return 1
fi

if ! [ -f "$DIETPI_IMAGE" ]; then

    printf "Do you want to download the DietPi image? (y/n)"
    read -r KEY_INPUT </dev/tty

    if [ "$KEY_INPUT" = "y" ]; then

        wget $DIETPI_URL
        unxz $DIETPI_IMAGE.xz

    fi
fi

if [ -f "$DIETPI_IMAGE" ]; then

    printf "Do you want to flash the DietPi image into SSD NVME drive? (y/n)"
    read -r KEY_INPUT </dev/tty

    if [ "$KEY_INPUT" = "y" ]; then

        echo "Removing and flashing DietPi image into SSD"
        sudo dd bs=1M if=/dev/zero of=/dev/$SSD_ID count=2000 status=progress && sudo sync
        sudo dd bs=1M if=$DIETPI_IMAGE of=/dev/$SSD_ID status=progress && sudo sync
        sudo fix_mmc_ssd.sh
        echo "DietPi has been successfully flashed"

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
export SSH_PUBKEY_FILE=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .ssh-key' $CONFIG_FILE)
export SERVER_USER=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .user' $CONFIG_FILE)

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

envsubst < $TEMPLATE_FILE > $OUTPUT_FILE

printf "Do you want to overwrite the target mount /mnt/$DIETPI_FILE? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then

    echo "Mounting the SSD boot and replace DietPi init"
    sudo mount /dev/$SSD_MOUNT /mnt/
    cat $OUTPUT_FILE | sudo tee /mnt/$DIETPI_FILE > /dev/null 2>&1
    sudo umount /mnt/ && sudo sync
    echo "DietPi init replaced"

fi

printf "Do you want to power off the device? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then
   sudo poweroff
fi

echo DONE!

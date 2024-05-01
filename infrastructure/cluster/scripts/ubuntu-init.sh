#!/bin/bash
#set -e

# Installation process (NVME only):
# 1. Prepare the SD card with the Ubuntu image (Orangepi5_1.1.8_ubuntu_jammy_server_linux6.1.43)
# 2. Remove all the data from SDD or destination storage.
# 3. Copy the image to the SDD or block storage (using 'dd' or any other method)
# 4. Copy the scripts to the SD card and ssh public key (using scp or sftp)
# 5. Run this script for a specific server: sbc-server-1, sbc-server-2, etc.. (i.e 'source ./scripts/ubuntu-init.sh sbc-server-1')
# 7.  Shutdown the device (sudo poweroff) and remove the SD card.

# How To use it:
# > source ./scripts/ubuntu-init.sh sbc-server-1
# > source ./scripts/ubuntu-init.sh sbc-server-1 ./config/servers.yaml
# > source ./scripts/ubuntu-init.sh $SERVER_NAME $CONFIG_FILE

SERVER_NAME=${1:-sbc-server-1}
CONFIG_FILE=${2:-./config/servers.yaml}

UBUNTU_IMAGE_PATH=.
UBUNTU_IMAGE_NAME=Orangepi5_1.1.8_ubuntu_jammy_server_linux6.1.43
UBUNTU_IMAGE_FILE=$UBUNTU_IMAGE_PATH/$UBUNTU_IMAGE_NAME.img
UBUNTU_IMAGE_COMPRESSED=$UBUNTU_IMAGE_PATH/$UBUNTU_IMAGE_NAME.7z
NETWORK_TEMPLATE_FILE=./config/templates/ubuntu/default.template.nmconnection
NETWORK_FILE=default.nmconnection
NETWORK_OUTPUT_PATH=/mnt/etc/NetworkManager/system-connections
SSH_OUTPUT_PATH=/mnt/home/orangepi/.ssh
SSHD_OUTPUT_FILE=/mnt/etc/ssh/sshd_config
HOSTNAME_OUTPUT_FILE=/mnt/etc/hostname
HOSTS_OUTPUT_FILE=/mnt/etc/hosts
SUDOERS_OUTPUT_FILE=/mnt/etc/sudoers
SSD_ID=nvme0n1
SSD_MOUNT=nvme0n1p2
USER_NAME=orangepi

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

    echo "WARN: Looking for compressed image: $UBUNTU_IMAGE_COMPRESSED"

    if ! [ -f "$UBUNTU_IMAGE_COMPRESSED" ]; then

        echo "ERROR: Image not found: $UBUNTU_IMAGE_COMPRESSED"
        return 1

    fi

    7z x "$UBUNTU_IMAGE_COMPRESSED" -o"$UBUNTU_IMAGE_PATH"

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

printf "Do you want to overwrite the default configuration? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then

    echo "Mounting the SSD boot and replace Ubuntu config"
    sudo mount /dev/$SSD_MOUNT /mnt/

    mkdir $SSH_OUTPUT_PATH
    touch $SSH_OUTPUT_PATH/authorized_keys
    cat "$SSH_PUBKEY_FILE" >> $SSH_OUTPUT_PATH/authorized_keys

    sudo grep -q "ChallengeResponseAuthentication" $SSHD_OUTPUT_FILE && sudo sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" $SSHD_OUTPUT_FILE || echo "ChallengeResponseAuthentication no" | sudo tee -a $SSHD_OUTPUT_FILE > /dev/null 2>&1
    sudo grep -q "^[^#]*PasswordAuthentication" $SSHD_OUTPUT_FILE && sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" $SSHD_OUTPUT_FILE || echo "PasswordAuthentication no" | sudo tee -a $SSHD_OUTPUT_FILE > /dev/null 2>&1

    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo tee -a $SUDOERS_OUTPUT_FILE > /dev/null 2>&1

    sudo mv $NETWORK_FILE $NETWORK_OUTPUT_PATH
    sudo chmod -R 600 $NETWORK_OUTPUT_PATH/$NETWORK_FILE
    sudo chown -R root:root $NETWORK_OUTPUT_PATH/$NETWORK_FILE

    CURRENT_HOSTNAME=$(cat $HOSTNAME_OUTPUT_FILE)
    echo $SERVER_HOSTNAME | sudo tee $HOSTNAME_OUTPUT_FILE > /dev/null 2>&1
    sudo sed -i "/127.0.1.1/s/$CURRENT_HOSTNAME/$SERVER_HOSTNAME/" $HOSTS_OUTPUT_FILE

    sudo umount /mnt/ && sudo sync
    echo "Ubuntu config replaced"

fi

printf "Do you want to power off the device? (y/n)"
read -r KEY_INPUT </dev/tty

if [ "$KEY_INPUT" = "y" ]; then
   sudo poweroff
fi

echo DONE!

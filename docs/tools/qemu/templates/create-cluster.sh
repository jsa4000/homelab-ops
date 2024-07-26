#!/bin/bash

# Usage:
# ./create-cluster.sh
# ./docs/tools/qemu/templates/create-cluster.sh

# NOTE: This stript is idempotent, so it will create different scrips that will be used to create the different resources.

# Input Variables

QEMU_FOLDER=/opt/homebrew/share/qemu
QEMU_IMAGE=/Users/jsantosa/VMs/images/ubuntu-22.04.3-live-server-arm64.iso
QEMU_BIOS=edk2-aarch64-code.fd
QEMU_UEFI=edk2-arm-vars.fd

QEMU_ROOTLESS=true
SOCKET_VMNET_CLIENT=$HOMEBREW_PREFIX/opt/socket_vmnet/bin/socket_vmnet_client
SOCKET_VMNET_SOCKET=$HOMEBREW_PREFIX/var/run/socket_vmnet

VM_BASE_IMAGE=base-image.qcow2
VM_SNAPSHOT_IMAGE=snapshot-image.qcow2
VM_SIZE=256G
VM_CPUS=4
VM_CORES=4
VM_MEMORY=8192
VM_SOCKETS=1
VM_THREADS=1
VM_NET1=net0
VM_NET2=net1
VM_PORT=50030
VM_INTERNAL_IP=10.0.2
VM_EXTERNAL_IP=192.168.205
VM_RANGE_IP=100
VM_DNS=8.8.8.8,8.8.8.4

VM_USERNAME=ubuntu
VM_PASSWORD=ubuntu
VM_SSH_PUBKEY=$HOME/.ssh/server_key.pub
VM_SSH_KEY=$HOME/.ssh/server_key
VM_HOST=server
VM_NUMBER=3

SUDOERS_OUTPUT_FILE=/etc/sudoers
SSHD_OUTPUT_FILE=/etc/ssh/sshd_config

# Outputs Variables
OUTPUT_FOLDER=/Users/jsantosa/VMs/cluster
CREATE_COMMAND_FILE=create.sh
RUN_COMMAND_FILE=run.sh
NETWORK_CONFIG_FILE=network.yaml
INIT_CONFIG_FILE=init.sh
PID_FILE=qemu.pid
BASE_FOLDER=base
CLONE_FOLDER=clone

# Create outpu folder if not exists
mkdir -p $OUTPUT_FOLDER

# Functions

function generate_mac_address {
    echo $(hexdump -n 6 -ve '1/1 "%.2x "' /dev/random | awk -v a="2,6,a,e" -v r="$RANDOM" 'BEGIN{srand(r);}NR==1{split(a,b,",");r=int(rand()*4+1);printf "%s%s:%s:%s:%s:%s:%s\n",substr($1,0,1),b[r],$2,$3,$4,$5,$6}')
}

function generate_create_base_command {
    BASE_OUTPUT_FOLDER=$1
    cat << EOF > $BASE_OUTPUT_FOLDER/$CREATE_COMMAND_FILE

# Copy ARM BIOS for aarch64
if ! [ -f "$BASE_OUTPUT_FOLDER/$QEMU_BIOS" ]; then
    cp $QEMU_FOLDER/$QEMU_BIOS $BASE_OUTPUT_FOLDER/$QEMU_BIOS
    cp $QEMU_FOLDER/$QEMU_UEFI $BASE_OUTPUT_FOLDER/$QEMU_UEFI
fi

# Create initial Disk to store the Base image to create SnapShots
if ! [ -f "$BASE_OUTPUT_FOLDER/$VM_BASE_IMAGE" ]; then
    qemu-img create -f qcow2 $BASE_OUTPUT_FOLDER/$VM_BASE_IMAGE $VM_SIZE
fi
EOF
    chmod +x $BASE_OUTPUT_FOLDER/$CREATE_COMMAND_FILE
}

function generate_network_config {
    NETWORK_OUTPUT_FOLDER=$1
    cat << EOF >> $NETWORK_OUTPUT_FOLDER/$NETWORK_CONFIG_FILE
network:
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s4:
      dhcp4: false
      addresses: [$VM_EXTERNAL_IP.$(($VM_RANGE_IP+$2))/24]
      routes:
      - to: default
        via: $VM_EXTERNAL_IP.1
      nameservers:
        addresses: [$VM_DNS]
  version: 2

EOF
}

function generate_init_config {
    CONFIG_OUTPUT_FOLDER=$1
    cat << EOF >> $CONFIG_OUTPUT_FOLDER/$INIT_CONFIG_FILE
# Enable no password for $VM_USERNAME user
echo "$VM_USERNAME ALL=(ALL) NOPASSWD:ALL" | tee -a $SUDOERS_OUTPUT_FILE > /dev/null 2>&1

# Disable password authentication using SSH
grep -q "ChallengeResponseAuthentication" $SSHD_OUTPUT_FILE && sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" $SSHD_OUTPUT_FILE || echo "ChallengeResponseAuthentication no" | tee -a $SSHD_OUTPUT_FILE > /dev/null 2>&1
grep -q "^[^#]*PasswordAuthentication" $SSHD_OUTPUT_FILE && sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" $SSHD_OUTPUT_FILE || echo "PasswordAuthentication no" | tee -a $SSHD_OUTPUT_FILE > /dev/null 2>&1

# Update distribution and install dependencies and tools. Phyton is needed for Ansible support
apt-get remove needrestart -y && apt-get update && apt-get upgrade -y && apt-get install net-tools iputils-ping python3-pip -y
EOF
}

function generate_create_clone_command {
    CLONE_OUTPUT_FOLDER=$1
    cat << EOF >> $CLONE_OUTPUT_FOLDER/$CREATE_COMMAND_FILE

# Copy UEFI Bios
if ! [ -f "$CLONE_OUTPUT_FOLDER/$QEMU_UEFI" ]; then
    cp $QEMU_FOLDER/$QEMU_UEFI $CLONE_OUTPUT_FOLDER/$QEMU_UEFI
fi

# Create snapshots $1 from the base image
if ! [ -f "$CLONE_OUTPUT_FOLDER/$VM_SNAPSHOT_IMAGE" ]; then
    qemu-img create -f qcow2 -F qcow2 -b $OUTPUT_FOLDER/$BASE_FOLDER/$VM_BASE_IMAGE $CLONE_OUTPUT_FOLDER/$VM_SNAPSHOT_IMAGE
fi

EOF
    chmod +x $CLONE_OUTPUT_FOLDER/$CREATE_COMMAND_FILE
}

function generate_run_vm_command {
    RUN_OUTPUT_FOLDER=$1
    # Generate MACs and port-forwarding
    VM_CURR_PORT=$(($VM_PORT+$3))
    VM_MAC1=$(generate_mac_address)
    VM_MAC2=$(generate_mac_address)

    if [[ "$QEMU_ROOTLESS" != "true" ]]; then
        cat << EOF > $RUN_OUTPUT_FOLDER/$RUN_COMMAND_FILE
sudo qemu-system-aarch64 \\
    -smp cpus=$VM_CPUS,sockets=$VM_SOCKETS,cores=$VM_CORES,threads=$VM_THREADS \\
    -m $VM_MEMORY \\
    -machine virt,accel=hvf,highmem=on \\
    -cpu host \\
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \\
    -drive if=virtio,format=qcow2,file=$RUN_OUTPUT_FOLDER/$2,cache=writethrough \\
    -drive if=pflash,format=raw,file=$OUTPUT_FOLDER/$BASE_FOLDER/$QEMU_BIOS,unit=0,readonly=on \\
    -drive if=pflash,format=raw,file=$RUN_OUTPUT_FOLDER/$QEMU_UEFI,unit=1 \\
    -device virtio-net-pci,mac=$VM_MAC1,netdev=$VM_NET1 \\
    -netdev user,id=$VM_NET1,hostfwd=tcp::$VM_CURR_PORT-:22 \\
    -device virtio-net-pci,mac=$VM_MAC2,netdev=$VM_NET2 \\
    -netdev vmnet-shared,id=$VM_NET2 \\
    -cdrom $QEMU_IMAGE \\
EOF
    else
        cat << EOF > $RUN_OUTPUT_FOLDER/$RUN_COMMAND_FILE
$SOCKET_VMNET_CLIENT $SOCKET_VMNET_SOCKET qemu-system-aarch64 \\
    -smp cpus=$VM_CPUS,sockets=$VM_SOCKETS,cores=$VM_CORES,threads=$VM_THREADS \\
    -m $VM_MEMORY \\
    -machine virt,accel=hvf,highmem=on \\
    -cpu host \\
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \\
    -drive if=virtio,format=qcow2,file=$RUN_OUTPUT_FOLDER/$2,cache=writethrough \\
    -drive if=pflash,format=raw,file=$OUTPUT_FOLDER/$BASE_FOLDER/$QEMU_BIOS,unit=0,readonly=on \\
    -drive if=pflash,format=raw,file=$RUN_OUTPUT_FOLDER/$QEMU_UEFI,unit=1 \\
    -device virtio-net-pci,mac=$VM_MAC1,netdev=$VM_NET1 \\
    -netdev user,id=$VM_NET1,hostfwd=tcp::$VM_CURR_PORT-:22 \\
    -device virtio-net-pci,mac=$VM_MAC2,netdev=$VM_NET2 \\
    -netdev socket,id=$VM_NET2,fd=3 \\
    -cdrom $QEMU_IMAGE \\
EOF
    fi

#   -netdev user,id=$VM_NET1,net=$VM_INTERNAL_IP.0/24,dhcpstart=$VM_INTERNAL_IP.$(($VM_RANGE_IP+$3)),hostfwd=tcp::$VM_CURR_PORT-:22 \\

    if [[ $3 == 0 ]]; then
        cat << EOF >> $RUN_OUTPUT_FOLDER/$RUN_COMMAND_FILE
    -monitor stdio

# In order to create the base image use following instructions:
# 1. Follow the instructions in order to install the OS from the image.
# 2. Create the base image using the user $VM_USERNAME, configure local and keyboard layout and enable SSH.
# 3. Once the installation has finished reboot the system
# 4. Check the connections using SSH port-forwarding to run command (-t for ask sudo permissions)

rm ~/.ssh/known_hosts
ssh $VM_USERNAME@localhost -p $VM_CURR_PORT

# 4. Perform initial configuration and bootsrapping for main packages

sshpass -p $VM_PASSWORD ssh-copy-id -i $VM_SSH_PUBKEY -p $VM_CURR_PORT $VM_USERNAME@localhost
scp -i $VM_SSH_KEY -P $VM_CURR_PORT $OUTPUT_FOLDER/$BASE_FOLDER/$INIT_CONFIG_FILE $VM_USERNAME@localhost:~/
echo $VM_PASSWORD | ssh -i $VM_SSH_KEY -t $VM_USERNAME@localhost -p $VM_CURR_PORT "sudo -S bash $INIT_CONFIG_FILE && rm $INIT_CONFIG_FILE"

# 5. Now you can enter using the public key

ssh -i $VM_SSH_KEY $VM_USERNAME@localhost -p $VM_CURR_PORT

# 6. Power off the VM

ssh -i $VM_SSH_KEY -t $VM_USERNAME@localhost -p $VM_CURR_PORT "sudo poweroff"

# 7. Optionalyy you can add folling configuration to you ssh config file at ~/.ssh/config, so the '-i' flag it's not neccesary to connect via ssh.

Host localhost
    HostName 127.0.0.1
    User     $VM_USERNAME
    IdentityFile $VM_SSH_KEY
    AddKeysToAgent yes
    UseKeychain yes
    IgnoreUnknown UseKeychain
    StrictHostKeyChecking no

EOF
    fi

    if [[ $3 != 0 ]]; then
        cat << EOF >> $RUN_OUTPUT_FOLDER/$RUN_COMMAND_FILE
    -pidfile $OUTPUT_FOLDER/$CLONE_FOLDER-$3/$PID_FILE \\
    -nographic

# From the base image use following command to configure hostname and Static IP:

scp -i $VM_SSH_KEY -P $VM_CURR_PORT $OUTPUT_FOLDER/$CLONE_FOLDER-$3/$NETWORK_CONFIG_FILE $VM_USERNAME@localhost:~/
ssh -i $VM_SSH_KEY -t $VM_USERNAME@localhost -p $VM_CURR_PORT "sudo hostnamectl set-hostname $VM_HOST-$3 && sudo mv ~/$NETWORK_CONFIG_FILE /etc/netplan/$NETWORK_CONFIG_FILE && sudo netplan generate && sudo netplan apply && sudo reboot"

# Power off the Viertua machine

ssh -i $VM_SSH_KEY -t $VM_USERNAME@localhost -p $VM_CURR_PORT "sudo poweroff"

EOF
    fi
    chmod +x $RUN_OUTPUT_FOLDER/$RUN_COMMAND_FILE
}

# Scripts

# Create Base Image Commands
mkdir $OUTPUT_FOLDER/$BASE_FOLDER
generate_create_base_command $OUTPUT_FOLDER/$BASE_FOLDER
generate_run_vm_command $OUTPUT_FOLDER/$BASE_FOLDER $VM_BASE_IMAGE 0
generate_init_config $OUTPUT_FOLDER/$BASE_FOLDER

# Create Clones Commands
for (( INDEX = 1; INDEX <= $VM_NUMBER; INDEX++ )); do

    CURRENT_CLONE_FOLDER=$OUTPUT_FOLDER/$CLONE_FOLDER-$INDEX

    mkdir $CURRENT_CLONE_FOLDER
    generate_create_clone_command $CURRENT_CLONE_FOLDER $INDEX
    generate_run_vm_command $CURRENT_CLONE_FOLDER $VM_SNAPSHOT_IMAGE $INDEX
    generate_network_config $CURRENT_CLONE_FOLDER $INDEX

done

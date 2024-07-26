# QEMU

## Installation

Create Ubuntu VM using QEMU

- Download Ubuntu Server for [ARM](https://ubuntu.com/download/server/arm)

- Install qemu

```bash
# Install Main packages
brew install rpm2cpio qemu
```

- Install and launch `socket_vmnet`

> [socket_vmnet](https://github.com/lima-vm/socket_vmnet) `vmnet.framework` support for **rootless** and VDE-less `QEMU`.

```bash
# Install socket_vmnet.
brew install socket_vmnet

########################################
## Start service using launchd and brew
########################################

# Install the launchd service
brew tap homebrew/services
# sudo is necessary for the next line (default gateway: 192.168.105.1)
sudo brew services start socket_vmnet
sudo brew services start socket_vmnet --file="docs/tools/qemu/templates/homebrew.mxcl.socket_vmnet.plist"

# Uninstall services
sudo brew services stop socket_vmnet

##############################
## Start manually the service
##############################

# Start socket_vmnet with specific gateway ip-address
mkdir -p "$HOMEBREW_PREFIX/var/run"
sudo "$HOMEBREW_PREFIX/opt/socket_vmnet/bin/socket_vmnet" --vmnet-gateway=192.168.205.1 "$HOMEBREW_PREFIX/var/run/socket_vmnet"
```

## Create Base Image

Create Base image from Ubuntu

```bash
# Create global environment variables
export QEMU_FOLDER=/opt/homebrew/share/qemu
export QEMU_IMAGE=../images/ubuntu-22.04.3-live-server-arm64.iso
export QEMU_BIOS=edk2-aarch64-code.fd
export QEMU_UEFI=edk2-arm-vars.fd

# Create Specific environment variables for current VM to be created
export QEMU_DISK=base-image.qcow2
export QEMU_MAC=3A:AA:06:A4:FE:E0
export QEMU_NET=net0

# Copy ARM BIOS for aarch64
cp $QEMU_FOLDER/$QEMU_UEFI $QEMU_UEFI
cp $QEMU_FOLDER/$QEMU_BIOS $QEMU_BIOS

# Create initial Disk to store the Base image to create SnapShots
qemu-img create -f qcow2 $QEMU_DISK 20G

# Create a new tab
#open -a iTerm .

# Create Base VM (qemu-system-{arch})
qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET \
    -monitor stdio \
    -cdrom $QEMU_IMAGE

# Set the main configuration hostname, user and password during the installation

export QEMU_DISK1='snapshot-01.qcow2'

# Create snapshots from the previous image (This is created in vagrant-qemu automatically)
qemu-img create -f qcow2 -F qcow2 -b $QEMU_DISK $QEMU_DISK1

# Start VM using snapshot(qemu-system-{arch})
qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK1,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET,hostfwd=tcp::50022-:22 \
    -monitor stdio

    # With output
    -monitor stdio

    # No output
    -pidfile qemu.pid \
    -daemonize -parallel null -monitor none -display none -vga none


# SSH into the machie using the forwarded port
ssh jsantosa@localhost -p 50022

# SSH and run commando (-t for ask sudo permissions)
ssh -t jsantosa@localhost -p 50022 'sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install net-tools iputils-ping python3 -y'

```

## Create Virtual Machine

- Create Global Environment Variables for Configuration

```bash
# Create global environment variables
export QEMU_FOLDER=/opt/homebrew/share/qemu
export QEMU_IMAGE=../images/ubuntu-22.04.1-live-server-arm64.iso
export QEMU_BIOS=edk2-aarch64-code.fd
export QEMU_UEFI=edk2-arm-vars.fd
```

- Create following content

```bash
# Create an empty file for persisting UEFI variables or using existing one (`edk2-arm-vars.fd`)
dd if=/dev/zero conv=sync bs=1m count=64 of=$QEMU_UEFI

# Or Copy existing one
#cp $QEMU_FOLDER/$QEMU_UEFI $QEMU_UEFI

# Copy ARM BIOS for aarch64
cp $QEMU_FOLDER/$QEMU_BIOS $QEMU_BIOS

# Create directory for temporal files
mkdir tmp/
```

- Run QEMU to create the Base Image

```bash
# Create Specific environment variables for current VM to be created
export QEMU_DISK=base-image.qcow2
export QEMU_MAC=3A:AA:06:A4:FE:E0
export QEMU_NET=net0

# Create initial Disk to store the Base image to create SnapShots
qemu-img create -f qcow2 $QEMU_DISK 10G

# Create Base VM (qemu-system-{arch})
qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET \
    -monitor stdio \
    -cdrom $QEMU_IMAGE

# Create a new tab
open -a iTerm .

# Start the VM (removing the cdrom)
sudo qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev vmnet-shared,id=$QEMU_NET \
    -nographic

# Create Base VM (qemu-system-{arch}) With Multiple interfaces
export QEMU_MAC1='3A:AA:06:A4:FE:E0'
export QEMU_MAC2='3A:AA:06:A4:FE:E1'
export QEMU_NET1='net0'
export QEMU_NET2='net1'
sudo qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC2,netdev=$QEMU_NET2 \
    -netdev vmnet-shared,id=$QEMU_NET2 \
    -device virtio-net-pci,mac=$QEMU_MAC1,netdev=$QEMU_NET1 \
    -netdev user,id=$QEMU_NET1,hostfwd=tcp::2222-:22 \
    -monitor stdio \
    -cdrom $QEMU_IMAGE

# It would open on a new Window with QEMU Monitor to start installing VM
# Use standard hostname, user and password for the main image
# Then install Linux, set the keyboard layout, region, updates, etc..

# Finally update the image with latest patches
sudo apt-get update && sudo apt-get upgrade -y
sudp apt-get install net-tools iputils-ping -y
```

- Create an snapshot to avoid installing the image every time.

```bash
export QEMU_DISK1='snapshot-01.qcow2'
export QEMU_DISK2='snapshot-02.qcow2'
export QEMU_DISK3='snapshot-03.qcow2'

# Create snapshots from the previous image
qemu-img create -f qcow2 -F qcow2 -b $QEMU_DISK $QEMU_DISK1
qemu-img create -f qcow2 -F qcow2 -b $QEMU_DISK $QEMU_DISK2
qemu-img create -f qcow2 -F qcow2 -b $QEMU_DISK $QEMU_DISK3
```

- Run different VMs using different snapshots

```bash
# VM1
export QEMU_DISK='snapshot-01.qcow2'
export QEMU_MAC='3A:AA:06:A4:FE:E0'
export QEMU_NET='net0'

# VM2
export QEMU_DISK='snapshot-02.qcow2'
export QEMU_MAC='3A:AA:06:A4:FE:E1'
export QEMU_NET='net1'

# Run Virtual Machine. No Network (VM1 & VM2)
qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET,hostfwd=tcp::2222-:22

# Without QEMU Window
qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET,hostfwd=tcp::2222-:22 \
    -parallel null -monitor none -display none -vga none -pidfile qemu.pid &

# Connect to SSH via Port-Forwarding
ssh 127.0.0.1 -p 2222

# Run using Shared Network (Similar to NAT in other Hypervisors)  (VM1 & VM2)
sudo qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev vmnet-shared,id=$QEMU_NET \
    -parallel null -monitor none -display none -vga none -pidfile qemu.pid &

    # With graphical option
    -nographic

# Since there is no Port-forward, open the VM, login-in and check the current ip
ifconfig

# USe the ping to know if VM is reachable from Host
ping 192.168.205.5

# Connect via SSH (Use the default Port 22) (If error use: rm /Users/jsantosa/.ssh/known_hosts)
ssh jsantosa@192.168.205.5

# If using & at the end of the command, the procces will be launched as child process (background)

# Get tue pid process
sudo cat qemu.pid

# Kill the process (using pidfile)
sudo kill -9 $(sudo cat qemu.pid)
```

- Use the proper Network to be used: host-only, bridged, shared (~NAT), etc..

```bash
# Host-only (with port-forwarding)
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev user,id=$QEMU_NET,hostfwd=tcp::2222-:22 \

# Shared Network (NAT, internal network with internet access)
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev vmnet-shared,id=$QEMU_NET

# Bridged Network (LAN external network with outside)
    -device virtio-net-pci,mac=$QEMU_MAC,netdev=$QEMU_NET \
    -netdev vmnet-bridged,id=$QEMU_NET,ifname=en0 \
```

- You should be able to install Ubuntu as normal
- If you want a desktop environment, you can install it using `sudo apt-get install ubuntu-desktop`

## Run QEMU rootless

Use `socket_vmnet` to use rootless. `socket_vmnet` must be installed and started.

```bash
# Copy ARM BIOS for aarch64
cp /opt/homebrew/share/qemu/edk2-aarch64-code.fd ./edk2-aarch64-code.fd
cp /opt/homebrew/share/qemu/edk2-arm-vars.fd ./edk2-arm-vars.fd

# Create initial Disk to store the Base image to create SnapShots
qemu-img create -f qcow2 ./base-image.qcow2 256G

# Create VM
"$HOMEBREW_PREFIX/opt/socket_vmnet/bin/socket_vmnet_client" "$HOMEBREW_PREFIX/var/run/socket_vmnet" qemu-system-aarch64 \
    -smp cpus=4,sockets=1,cores=4,threads=1 \
    -m 8192 \
    -machine virt,accel=hvf,highmem=on \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=./base-image.qcow2,cache=writethrough \
    -drive if=pflash,format=raw,file=./edk2-aarch64-code.fd,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=./edk2-arm-vars.fd,unit=1 \
    -device virtio-net-pci,mac=ee:db:ea:07:fe:d9,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::50030-:22 \
    -device virtio-net-pci,mac=1e:e0:2b:b1:9b:97,netdev=net1 \
    -netdev socket,id=net1,fd=3 \
    -cdrom /Users/jsantosa/VMs/images/ubuntu-22.04.3-live-server-arm64.iso \
    -monitor stdio

## SSH into the VM
ssh ubuntu@localhost -p 50030

# 4. Perform initial configuration and bootsrapping for main packages
ssh-copy-id -i /Users/jsantosa/.ssh/server_key.pub -p 50030 ubuntu@localhost
ssh -i /Users/jsantosa/.ssh/server_key -t ubuntu@localhost -p 50030 "echo ubuntu | sudo -S apt-get remove needrestart -y && sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install net-tools iputils-ping python3-pip -y"

# 5. Now you can enter using the public key
ssh -i /Users/jsantosa/.ssh/server_key ubuntu@localhost -p 50030

# 6. Power off the VM
ssh -i /Users/jsantosa/.ssh/server_key -t ubuntu@localhost -p 50030 "echo ubuntu | sudo -S poweroff"

# 7. Optionalyy you can add folling configuration to you ssh config file at ~/.ssh/config, so the '-i' flag it's not neccesary to connect via ssh.

Host localhost
    HostName 127.0.0.1
    User     ubuntu
    IdentityFile /Users/jsantosa/.ssh/server_key
    AddKeysToAgent yes
    UseKeychain yes
    IgnoreUnknown UseKeychain
    StrictHostKeyChecking no

```

## EXAMPLE

```bash
# Create global environment variables
export QEMU_FOLDER='/System/Volumes/Data/opt/homebrew/Cellar/qemu/7.1.0/share/qemu'
export QEMU_IMAGE='../images/ubuntu-22.04.1-live-server-arm64.iso'
export QEMU_BIOS='edk2-aarch64-code.fd'
export QEMU_UEFI='edk2-arm-vars.fd'

export QEMU_DISK='snapshot-01.qcow2'
export QEMU_MAC1='3A:AA:06:A4:FE:E0'
export QEMU_MAC2='3A:AA:06:A4:FE:E1'
export QEMU_NET1='net0'
export QEMU_NET2='net1'
export QEMU_SSH='2222'

export QEMU_DISK='snapshot-02.qcow2'
export QEMU_MAC1='3A:AA:06:A4:FE:E2'
export QEMU_MAC2='3A:AA:06:A4:FE:E3'
export QEMU_NET1='net0'
export QEMU_NET2='net1'
export QEMU_SSH='2223'

# Create VM with multiple Network Interfaces
sudo qemu-system-aarch64 \
    -smp cpus=2,sockets=1,cores=2,threads=1 \
    -m 2048 \
    -machine virt,accel=hvf,highmem=off \
    -cpu host \
    -device virtio-gpu-pci -device qemu-xhci -device usb-kbd -device usb-tablet \
    -drive if=virtio,format=qcow2,file=$QEMU_DISK,cache=writethrough \
    -drive if=pflash,format=raw,file=$QEMU_BIOS,unit=0,readonly=on \
    -drive if=pflash,format=raw,file=$QEMU_UEFI,unit=1 \
    -device virtio-net-pci,mac=$QEMU_MAC1,netdev=$QEMU_NET1 \
    -netdev user,id=$QEMU_NET1,hostfwd=tcp::$QEMU_SSH-:22 \
    -device virtio-net-pci,mac=$QEMU_MAC2,netdev=$QEMU_NET2 \
    -netdev vmnet-shared,id=$QEMU_NET2 \
    -parallel null -monitor none -display none -vga none -pidfile qemu.pid &

# Bridged Interface
    -netdev vmnet-bridged,id=$QEMU_NET2,ifname=en0

# Connect to SSH via Port-Forwarding
ssh 127.0.0.1 -p 2222
```

## Configuration

### Static IP

Crate a bash file into `/etc/netplan` to assign static IPs

```bash
# Edit the file or create a new one
sudo vi /etc/netplan/00-installer-config.yaml
```

Put the following content.

```yaml
network:
  ethernets:
    enp0s3:
      dhcp4: false
      addresses: [192.168.205.100/24]
      routes:
      - to: default
        via: 192.168.205.1
      nameservers:
        addresses: [8.8.8.8,8.8.8.4]
  version: 2
```

Apply and test the changes.

```bash
# Apply and test the changes.
sudo netplan try
```

### Hostname

Change Server Hostname

```bash
# Change hostname
sudo hostnamectl set-hostname server-01
```

### Resize Disk

Command to expand the disk of an already created image

```bash
# Resize image
qemu-img resize vm-image.qcow2 +30G
```

## Virtual Block

Linux users can have a virtual block device called a `loop device` that maps a normal file to a virtual block, making it ideal for tasks related to isolating processes.

```bash
# Get Loop devices
losetup -l

# Search for a particular Virtual block
losetup /dev/loop0

# Create a loop device (1GB)

# 1. Create a block file called "blockfile" (within current directory)
dd if=/dev/zero of=blockfile bs=1M count=1024

# 2. Create the loop device (ref to the previous file created)
sudo losetup /dev/loop0 blockfile

# Uae lsblk or losetup to verify the loop device has been created

# 3. You can partition and mount the volumes as disks

# 4. Detach the loop device
sudo losetup -d /dev/loop0

```

## References

- [https://gist.github.com/max-i-mil/f44e8e6f2416d88055fc2d0f36c6173b]
- [https://patchew.org/QEMU/20211207101828.22033-1-yaroshchuk2000@gmail.com/]
- [https://linuxconfig.org/how-to-create-loop-devices-on-linux]
- [https://github.com/rook/rook/issues/7206]
- [https://medium.com/techlogs/configuring-rook-with-external-ceph-6b4b49626112]

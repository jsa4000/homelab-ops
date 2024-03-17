# Orange Pi OS

## Prepare SD Card

1. Go to official Orange Pi [Web Site](http://www.orangepi.org).
2. Go to section [Service & Download](http://www.orangepi.org/html/serviceAndSupport/index.html) and select `Download`.
3. Search for the specific **Orange Pi** model (i.e `Orange Pi 5`).
4. Download the **Ubuntu Image** (i.e `Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z`). This tutorial is mean for that specific Linux distribution.
5. Flash the image into a SD Card using [balenaEtcher](https://etcher.balena.io/).

## Initialize

Put the SD Card into the board and turn on the device.

> NOTE: Go to your [Router Gateway](http://192.168.3.1) in order to check the IP Address of the device (i.e `192.168.3.49`). This is useful since *headless* installations an external monitor is not needed.

```bash
# [Optional] Remove previous known host for previous connections
rm ~/.ssh/known_hosts

# SSH into the machine (orangepi/orangepi)
ssh orangepi@192.168.3.49

# Update the dependencies
sudo apt update && sudo apt upgrade -y

# Install compression utils
sudo apt install p7zip-full -y

# [Optional] Use the orange pi utility do some basic configuration: update firmware, system configuration, software, etc..
sudo orangepi-config
```

## SPI Flash

In order to boot up from the SDD drive is necessary to flash the SPI with the proper `loader`.

```bash
# You can use orangepi-config and select the desired mode, however you can do manually using the process bellow
sudo nand-sata-install
```

### NVME SPI Flash

By default Orange PI can detect NVME drives, so once the device is plugin into the board it should be detected.

```bash
# List Block devices (you should see a device called 'nvme0n1')
sudo lsblk

# [Optional] Erase the content of the SPI Flash
sudo dd if=/dev/zero of=/dev/mtdblock0 bs=1M count=1 && sudo sync

# Use following command to Flash SPI with the loader so it boot from the NVME SSD (sudo find / -name rkspi_loader.img)
sudo dd if=/usr/lib/linux-u-boot-legacy-orangepi5_1.1.8_arm64/rkspi_loader.img of=/dev/mtdblock0 conv=notrunc && sudo sync

# Reboot the system, however it's not necessary
sudo reboot
```

### SATA SPI Flash

By default Orange PI DO NOT detect SATA drives, so once the device is plugin into the board it's not recognized.

```bash
# List Block devices (you should not see a device called 'sda')
sudo lsblk

# [Optional] Erase the content of the SPI Flash
sudo dd if=/dev/zero of=/dev/mtdblock0 bs=1M count=1 && sudo sync

# Use following command to Flash SPI with the loader so it boot from the SATA SSD (sudo find / -name rkspi_loader_sata.img)
dd if=/usr/share/orangepi5/rkspi_loader_sata.img of=/dev/mtdblock0 && sudo sync

# Enable SATA devices:
# 1. Activate the SATA overlay in 'orangepiEnv.txt' (sudo find / -name orangepiEnv.txt):
# 2. List all the files at /boot/dtb/rockchip/overlay (sudo ls /boot/dtb/rockchip/overlay | grep sata)
echo "overlays=ssd-sata0 ssd-sata2" | sudo tee -a /boot/orangepiEnv.txt

# Reboot the system
sudo reboot

```

## SSD Installation

Download the image that is going to be installed into the SSD drive and copy it into the SD.

```bash
# From remote computer copy the image to the SD via SCP.
scp "/Users/jsantosa/Downloads/tools/orangepi/Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z" orangepi@192.168.3.49:~/

# From the orange pi Unzip the content if necessary
7za x Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z
```

### NVME SSD Installation

```bash
# Delete SSD content by setting zeros to the first data blocks
sudo dd bs=1M if=/dev/zero of=/dev/nvme0n1 count=2000 status=progress && sudo sync

# Clone the SD into SSD (very slow)
#sudo cat /dev/mmcblk0 > /dev/nvme0n1

# Copy the image content to the SSD
sudo dd bs=1M if=Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.img of=/dev/nvme0n1 status=progress && sudo sync

# Fix the SD and SSD since it uses the same identifier
sudo fix_mmc_ssd.sh # or sudo tune2fs -U random /dev/mmcblk1p2

# Power off and remove the SD card
sudo poweroff
```

### SATA SSD Installation

```bash
# Delete SSD content by setting zeros to the first data blocks
sudo dd bs=1M if=/dev/zero of=/dev/sda count=2000 status=progress && sudo sync

# Clone the SD into SSD (very slow)
#sudo cat /dev/mmcblk0 > /dev/nvme0n1

# Copy the image content to the SSD
sudo dd bs=1M if=Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.img of=/dev/sda status=progress && sudo sync

# Fix the SD and SSD since it uses the same identifier
sudo fix_mmc_ssd.sh # or sudo tune2fs -U random /dev/mmcblk1p2

# Add the STAT overlay to the SSD boot in order to be recognized
sudo mount /dev/sda1 /mnt/
echo "overlays=ssd-sata0 ssd-sata2" | sudo tee -a /mnt/orangepiEnv.txt
sudo umount /mnt/ && sudo sync

# Power off and remove the SD card
sudo poweroff

```

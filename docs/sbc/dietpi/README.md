# DietPi OS

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
sudo apt install p7zip-full gettext-base -y

# Install yq
wget https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_arm64.tar.gz -O - | tar xz && mv yq_linux_arm64 /usr/bin/yq

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

1. Go to official Diet Pi [Web Site](https://dietpi.com).
2. Go to section [Download](https://dietpi.com/#download).
3. Search for the specific **Orange Pi** model (i.e `Orange Pi 5`).
4. Download the image (i.e `DietPi_OrangePi5-ARMv8-Bookworm.img.xz`).

Copy the image into the Orange Pi using SSH or SFTP.

```bash
# From remote computer copy the image to the SD via SCP.
scp "/Users/jsantosa/Downloads/tools/orangepi/DietPi_OrangePi5-ARMv8-Bookworm.img.xz" orangepi@192.168.3.49:~/

# From the orange pi Unzip the content if necessary
7za x DietPi_OrangePi5-ARMv8-Bookworm.img.xz
```

### Generate SSH keys

```bash
# [Optional] If ssh folder does not exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Do not fill anything in next command just enter
ssh-keygen -t rsa -b 4096 -C "jsa4000@gmail.com" -f ~/.ssh/server_key

# [Optional] Copy keys to each node or use AUTO_SETUP_SSH_PUBKEY in 'dietpi.txt' config instead
ssh-copy-id -i ~/.ssh/server_key.pub root@192.168.3.100

# Replace the content of AUTO_SETUP_SSH_PUBKEY for this key and set SOFTWARE_DISABLE_SSH_PASSWORD_LOGINS to 0
cat ~/.ssh/server_key.pub
```

### NVME SSD Installation

```bash
# Delete SSD content by setting zeros to the first data blocks
sudo dd bs=1M if=/dev/zero of=/dev/nvme0n1 count=2000 status=progress && sudo sync

# Clone the SD into SSD (very slow)
#sudo cat /dev/mmcblk0 > /dev/nvme0n1

# Copy the image content to the SSD
sudo dd bs=1M if=~/DietPi_OrangePi5-ARMv8-Bookworm.img of=/dev/nvme0n1 status=progress && sudo sync

# Check the data blocks. Notice the new partitions are not extended yet.
sudo lsblk

# Fix the SD and SSD since it uses the same identifier
sudo fix_mmc_ssd.sh # or sudo tune2fs -U random /dev/mmcblk1p2

# Copy the auto configuration
scp -rp "./docs/dietpi" orangepi@192.168.3.49:~/

sudo mount /dev/nvme0n1p2 /mnt/
cat ~/dietpi/templates/dietpi.txt | sudo tee -a /mnt/dietpi.txt
sudo umount /mnt/ && sudo sync

# Power off and remove the SD card
sudo poweroff

```

### SATA SSD Installation

> Check DietPi documentation to check the process to add SATA overlays to the OS (`dietpiEnv.txt`)

## Test

```bash
# [Optional] Remove previous known host for previous connections
rm ~/.ssh/known_hosts

# SSH into the machine (root/dietpi)
ssh root@192.168.3.100

# SSH into the machine (private key)
ssh -i ~/.ssh/server_key root@192.168.3.100
ssh -i ~/.ssh/server_key dietpi@192.168.3.100

```

Using the SSH config file so it's not necessary to enter the private key anymore.

`~/.ssh/config`

```bash

Host sbc-server-1
    HostName 192.168.3.100
    User     dietpi
    IdentityFile ~/.ssh/server_key

Host sbc-server-2
    HostName 192.168.3.101
    User     dietpi
    IdentityFile ~/.ssh/server_key

Host sbc-server-3
    HostName 192.168.3.102
    User     dietpi
    IdentityFile ~/.ssh/server_key

```

```bash
# [Optional] Remove previous known host for previous connections
rm ~/.ssh/known_hosts

# SSH using the user@host specified in the SSH config
ssh dietpi@sbc-server-1
ssh dietpi@sbc-server-2
ssh dietpi@sbc-server-3

# Power off
ssh dietpi@sbc-server-1 'sudo poweroff'
ssh dietpi@sbc-server-2 'sudo poweroff'
ssh dietpi@sbc-server-3 'sudo poweroff'

# Reboot
ssh dietpi@sbc-server-1 'sudo reboot'
ssh dietpi@sbc-server-2 'sudo reboot'
ssh dietpi@sbc-server-3 'sudo reboot'
```

## First Boot

DietPi offers the option for an automatic first boot installation. See section [How to do an automatic base installation at first boot](https://dietpi.com/docs/usage/#how-to-do-an-automatic-base-installation-at-first-boot-dietpi-automation) for details.

Following are the most important changes to take a loot in `dietpi.txt`.

```bash
AUTO_SETUP_LOCALE=es_ES.UTF-8
AUTO_SETUP_KEYBOARD_LAYOUT=es
AUTO_SETUP_TIMEZONE=Europe/Madrid
AUTO_SETUP_NET_WIFI_COUNTRY_CODE=ES

AUTO_SETUP_NET_USESTATIC=1
AUTO_SETUP_NET_STATIC_IP=192.168.3.101
AUTO_SETUP_NET_STATIC_MASK=255.255.255.0
AUTO_SETUP_NET_STATIC_GATEWAY=192.168.3.1
AUTO_SETUP_NET_STATIC_DNS=192.168.3.1

AUTO_SETUP_NET_HOSTNAME=Server01

AUTO_SETUP_HEADLESS=1
AUTO_SETUP_SSH_SERVER_INDEX=-2
#AUTO_SETUP_SSH_PUBKEY=ssh-ed25519 AAAAAAAA111111111111BBBBBBBBBBBB222222222222cccccccccccc333333333333 mySSHkey

AUTO_SETUP_RAMLOG_MAXSIZE=200
AUTO_SETUP_WEB_SERVER_INDEX=0
AUTO_SETUP_DESKTOP_INDEX=0
AUTO_SETUP_BROWSER_INDEX=0

AUTO_SETUP_AUTOSTART_TARGET_INDEX=7
AUTO_SETUP_AUTOSTART_LOGIN_USER=root
AUTO_SETUP_GLOBAL_PASSWORD=dietpi
AUTO_SETUP_AUTOMATED=1
SURVEY_OPTED_IN=0

# OpenSSH Client
AUTO_SETUP_INSTALL_SOFTWARE_ID=0
# OpenSSH Server
AUTO_SETUP_INSTALL_SOFTWARE_ID=105
# Python 3 pip
AUTO_SETUP_INSTALL_SOFTWARE_ID=130

```

### Diet Software

You can install as many software as you want during the setup. Since DietPi pretend to be minimalistic, it does not provide a large catalogue of software by default. You can take a look to the [software list](https://github.com/MichaIng/DietPi/wiki/DietPi-Software-list).

```bash
# OpenSSH Client
AUTO_SETUP_INSTALL_SOFTWARE_ID=0
# OpenSSH Server
AUTO_SETUP_INSTALL_SOFTWARE_ID=105
# Git
AUTO_SETUP_INSTALL_SOFTWARE_ID=17
# Python 3 pip
AUTO_SETUP_INSTALL_SOFTWARE_ID=130

```

Check packages currently installed in debian or ubuntu (`apt`)

```bash
# Check packages installed
dpkg -l
```

### Random MAC Address

[Orange Pi 5 - MAC address changes on reboot](https://github.com/MichaIng/DietPi/issues/6663)
[rk_vendor_read eth mac address failed](https://github.com/Joshua-Riek/ubuntu-rockchip/issues/274)

```bash
# Run following command
sudo journalctl | grep rk_gmac-dwmac

01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: Enable RX Mitigation via HW Watchdog Timer
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: rk_get_eth_addr: rk_vendor_read eth mac address failed (-1)
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: rk_get_eth_addr: generate random eth mac address: b2:23:c3:61:ba:23
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: rk_get_eth_addr: rk_vendor_write eth mac address failed (-1)
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: rk_get_eth_addr: id: 1 rk_vendor_read eth mac address failed (-1)
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: rk_get_eth_addr: mac address: b2:23:c3:61:ba:23
May 01 16:26:49 DietPi kernel: rk_gmac-dwmac fe1c0000.ethernet: device MAC address b2:23:c3:61:ba:23
```

Creating `/etc/network/interfaces.d/eth0` with content

```bash
# Create file with the fixed MAC Address
sudo tee -a /etc/network/interfaces.d/eth0 > /dev/null <<EOT
iface eth0 inet dhcp
hwaddress ether 8a:33:ce:b3:b0:b9
EOT

# Restart Networking
systemctl restart networking

# check the MAC Address has been assigned
ip address | grep 8a:33:ce:b3:b0:b9
```

Using `dietpi-config` is necessary to add it into the existing interface (`eth0`) already created at `/etc/network/interfaces`

```bash
# Add new line with the MAC Address after 'iface eth0 inet static'
IFACE_FILE=/etc/network/interfaces
MAC_ADDRESS=8a:33:ce:b3:b0:b9
HWADDRESS="hwaddress ether $MAC_ADDRESS"
IFACE_STR="iface eth0 inet static"
sed -i "s|$IFACE_STR|$IFACE_STR\n$HWADDRESS|g" $IFACE_FILE # For macos use 'sed -i "" "s|xx|yy|g file

# Restart Networking
systemctl restart networking
```

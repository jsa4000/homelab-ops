# Cluster

## Installation

The installation are divided into two steps:

1. Prepare a SD card with default image.
2. Install the SPI loader to enable NVME drive.
3. Install the DietPi using default configuration.

### Prepare SD Card

In order to prepare the SD card you must follow the steps:

1. Download the *Ubuntu Orange Pi* image from the official [web site](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-pi-5.html) (`Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z`)
2. Flash a SD Card using `balenaEcher` using previous image downloaded.

### Install SPI Loader

Install the SPI loader to run from `NVME` drive. You must follow the steps:

> This is **only** for the first time you install the device, so SPI loader will reamin in the memory.

1. Plug the SD Card into the device (`Orange Pi`) and power on.
2. SSH into the device; use the [Router dashboard](http://192.168.3.1/) to obtain the IP Address of the device (`ssh orangepi@192.168.3.61` (`orangepi/orangepi`)).
3. Copy the scripts to the SD card and ssh public key, using `scp` or `sftp`.
4. Run this script (source `./scripts/orangepi-init.sh`)

How To use it:

```bash
# ssh public key must be copied to the path defined in servers.yaml. i.e "$HOME/.ssh/server_key.pub"
# Go to folder copied with scripts
cd cluster

# Initialize OerangPi with default values.
source ./scripts/orangepi-init.sh
```

### DietPi Installation

These steps are done by the `dietpi-init.sh` script automatically.

1. Prepare the SD card with the DietPI image (`DietPi_OrangePi5-ARMv8-Bookworm.img.xz`). Only the first time for the first device.
2. Remove all the data from SDD or destination storage.
3. Copy the image to the SDD or block storage (using `dd` or any other method)
4. Copy the scripts to the SD card and ssh public key (using `scp` or `sftp`)
5. Run this script for a specific server: `sbc-server-1`, `sbc-server-2`, etc.. (i.e `source ./scripts/dietpi-init.sh sbc-server-1`)
6. Check the configuration set at `/mnt/dietpi.txt`
7. Shutdown the device (`sudo poweroff`) and remove the SD card.

```bash
# Command line and parameters to be used to install dietpi
# source ./scripts/dietpi-init.sh $SERVER_NAME $CONFIG_FILE $OUTPUT_FILE

# Install Diet-pi into 'sbc-server-1'
source ./scripts/dietpi-init.sh sbc-server-1

# Install Diet-pi into 'sbc-server-1' using custom configuration file
source ./scripts/dietpi-init.sh sbc-server-1 ./config/servers.yaml ./dietpi.txt

# Test current device by access using ssh.
ssh orangepi@192.168.3.100
```

### SSH Configurations

```bash
# Add cluster ssh configuration
# source ./scripts/get-ssh-config.sh $CONFIG_FILE $SSH_KEY_FILE $OUTPUT_FILE

# Install with default settings
source ./scripts/get-ssh-config.sh

source ./scripts/get-ssh-config.sh ./config/servers.yaml  ~/.ssh/server_key $HOME/.ssh/ssh_config

```

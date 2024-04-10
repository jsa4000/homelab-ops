# Cluster

## Installation

The installation are divided into two steps:

1. Prepare the SD card and install the SPI loader to enable NVME drive.
2. Install the DietPi Os using default configuration.

### Prepare Orange Pi

In order to prepare the SD card and install the SPI loader to be able to run from NVME drive, you must follow the steps:

1. Download the *Ubuntu Orange Pi* image from the official [web site](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-pi-5.html) (i.e. `Orangepi5_1.1.8_ubuntu_jammy_server_linux6.1.43.7z` or `Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z`)
2. Flash a SD Card using `balenaEcher` using previous image downloaded.
3. Plug the SD Card into the device (`Orange Pi`) and power on.
4. SSH into the device, use the Router to obtain the IP Address of the device (`ssh orangepi@192.168.3.49` (`orangepi/orangepi`)). This is for the first time, since in the next step a static IP will be configured.
5. Copy the scripts to the SD card and ssh public key (using `scp` or `sftp`). Or using git (`git clone https://github.com/jsa4000/homelab-ops.git`)
6. Run this script (source `./scripts/orangepi-init.sh`)

Notes:

- The SD Card can be reused to configure multiple devices
- The first time a device is configure this script should be run, because the SPI Flash loader.

How To use it:

```bash
# Initialize OerangPi with default values.
source ./scripts/orangepi-init.sh
```

### DietPi Installation

Installation process (NVME only):

1. Prepare the SD card with the DietPI image (`DietPi_OrangePi5-ARMv8-Bookworm.img.xz`)
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

```

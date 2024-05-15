# Cluster

## Installation

The installation are divided into two steps:

1. Prepare a SD card with default image (only the first time).
2. Install the SPI loader to enable NVME drive.
3. Install the DietPi/Ubuntu using default configuration.

### Prepare SD Card

In order to prepare the SD card you must follow the steps:

1. Download the *Ubuntu Orange Pi* image from the official [web site](http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-pi-5.html) (`Orangepi5_1.1.8_ubuntu_jammy_server_linuxX.YY.ZZZ.7z`)
2. Flash a SD Card using `balenaEcher` using previous image downloaded.

### Initialize

Install the SPI loader to run from `NVME` drive. You must follow the steps:

> This is **only** for the first time you install the device, so SPI loader will remain in memory.

1. Plug the SD Card into the device (`Orange Pi`) and power on.
2. Get the IP Address of the device by using the [Router dashboard](http://192.168.3.1/).
3. SSH into the device `ssh orangepi@192.168.3.61` (`orangepi/orangepi`). Use `rm ~/.ssh/known_hosts` to remove previous connections.
4. Copy the scripts to the SD card using `scp` or `sftp`.
5. Copy the ssh public-key to be used for management.
6. Run this script (`source ./scripts/orangepi-init.sh`)

How To use it:

```bash
# Remove previous connections
rm ~/.ssh/known_hosts
# ssh into the device (orangepi/orangepi)
ssh orangepi@192.168.3.61

# ssh public key must be copied to the path defined in servers.yaml. i.e "$HOME/.ssh/server_key.pub"
# Go to folder copied with scripts
cd cluster

# Initialize OerangPi with default values.
source ./scripts/orangepi-init.sh

# Do not install SPI Loader if already installed.
```

### DietPi Installation

These steps are done by the `dietpi-init.sh` script automatically.

1. Prepare the SD card with the DietPI image (`DietPi_OrangePi5-ARMv8-Bookworm.img.xz`).
2. Remove all the data from SDD or destination storage.
3. Copy the image to the SDD or block storage (using `dd` or any other method)
4. Copy the scripts to the SD card and ssh public key (using `scp` or `sftp`)
5. Run this script for a specific server: `sbc-server-1`, `sbc-server-2`, etc.. (i.e `source ./scripts/dietpi-init.sh sbc-server-1`)
6. Check the configuration set at `/mnt/dietpi.txt`
7. Shutdown the device (`sudo poweroff`) and remove the SD card.

```bash
# ssh into the device (orangepi/orangepi)
ssh orangepi@192.168.3.61

# ssh public key must be copied to the path defined in servers.yaml. i.e "$HOME/.ssh/server_key.pub"
# Go to folder copied with scripts
cd cluster

# Command line and parameters to be used to install dietpi
# source ./scripts/dietpi-init.sh $SERVER_NAME $CONFIG_FILE $OUTPUT_FILE

# Install Diet-pi into 'sbc-server-1'
source ./scripts/dietpi-init.sh sbc-server-1

# Install Diet-pi into 'sbc-server-1' using custom configuration file
source ./scripts/dietpi-init.sh sbc-server-1 ./config/servers.yaml ./dietpi.txt

# Test current device by access using ssh.
ssh dietpi@192.168.3.100
```

### Ubuntu Installation

These steps are done by the `ubuntu-init.sh` script automatically.

1. Prepare the SD card with the Ubuntu image (`Orangepi5_1.1.8_ubuntu_jammy_server_linux5.10.160.7z`).
2. Remove all the data from SDD or destination storage.
3. Copy the image to the SDD or block storage (using `dd` or any other method)
4. Copy the scripts to the SD card and ssh public key (using `scp` or `sftp`)
5. Run this script for a specific server: `sbc-server-1`, `sbc-server-2`, etc.. (i.e `source ./scripts/ubuntu-init.sh sbc-server-1`)
6. Check the configuration modified.
7. Shutdown the device (`sudo poweroff`) and remove the SD card.

```bash
# ssh into the device (orangepi/orangepi)
ssh orangepi@192.168.3.61

# ssh public key must be copied to the path defined in servers.yaml. i.e "$HOME/.ssh/server_key.pub"
# Go to folder copied with scripts
cd cluster

# Command line and parameters to be used to install ubuntu
# source ./scripts/ubuntu-init.sh $SERVER_NAME $CONFIG_FILE $OUTPUT_FILE

# Install ubuntu into 'sbc-server-1'
source ./scripts/ubuntu-init.sh sbc-server-1

# Install ubuntu into 'sbc-server-1' using custom configuration file
source ./scripts/ubuntu-init.sh sbc-server-1 ./config/servers.yaml

# Test current device by access using ssh.
ssh orangepi@192.168.3.100
```

### Joshua Installation

These steps are done by the `cloud-init.sh` script automatically.

1. Prepare the SD card
2. Remove all the data from SDD or destination storage.
3. Copy the image to the SDD or block storage (using `dd` or any other method)
4. Copy the scripts to the SD card and ssh public key (using `scp` or `sftp`)
5. Run this script for a specific server: `sbc-server-1`, `sbc-server-2`, etc.. (i.e `source ./scripts/cloud-init.sh sbc-server-1`)
6. Check the configuration modified.
7. Shutdown the device (`sudo poweroff`) and remove the SD card.

```bash
# ssh into the device (orangepi/orangepi)
ssh orangepi@192.168.3.61

# ssh public key must be copied to the path defined in servers.yaml. i.e "$HOME/.ssh/server_key.pub"
# Go to folder copied with scripts
cd cluster

# Command line and parameters to be used to install ubuntu
# source ./scripts/cloud-init.sh $SERVER_NAME $CONFIG_FILE $OUTPUT_FILE

# Install ubuntu into 'sbc-server-1'
source ./scripts/cloud-init.sh sbc-server-1

# Install ubuntu into 'sbc-server-1' using custom configuration file
source ./scripts/cloud-init.sh sbc-server-1 ./config/servers.yaml

# Test current device by access using ssh. ('rm ~/.ssh/known_hosts')
ssh ubuntu@192.168.3.100
```

### SSH Configurations

The `ssh-agent` is a helper program that keeps track of users' identity **keys** and their **passphrases**. The agent can then use the keys to log into other servers **without** having the user type in a password or passphrase again. This implements a form of **single sign-on** (SSO).

The SSH agent is used for SSH public key authentication. It uses SSH keys for authentication. Users can create SSH keys using the `ssh-keygen` command and install them on servers using the `ssh-copy-id` command.

Following a script to automatize the generation of this file:

```bash
# Add cluster ssh configuration
# source ./scripts/get-ssh-config.sh $CONFIG_FILE $SSH_KEY_FILE $OUTPUT_FILE

# Install with default settings
source ./scripts/get-ssh-config.sh

source ./scripts/get-ssh-config.sh ./config/servers.yaml  ~/.ssh/server_key $HOME/.ssh/ssh_config

# Use one of the following ways to connect to server.
ssh dietpi@192.168.3.100
ssh dietpi@sbc-server-1

# Connect using the ssh key
 ssh -i /Users/jsantosa/.ssh/server_key -t dietpi@192.168.3.100
```

## Benchmark

### Geekbench

```bash
# Get linux distribution info
lsb_release -a

# Download the file and untar
wget -qO- https://cdn.geekbench.com/Geekbench-6.3.0-LinuxARMPreview.tar.gz | tar xvz

# Execute Benchmakr
./Geekbench-6.3.0-LinuxARMPreview/geekbench_aarch64

# Ubuntu 22.04.3 LTS (Joshua) - Single-Core 790 Score - Multi-Core 3184 Score
# Ubuntu 24.04.3 LTS (Joshua) - Single-Core 761 Score - Multi-Core 3166 Score
```

### SpeedTest

```bash
# Install speedtest cli
sudo apt install speedtest-cli

# Run tests
speedtest-cli --secure
```

### PiBenchmark

```bash
# Run following command
sudo curl https://raw.githubusercontent.com/TheRemote/PiBenchmarks/master/Storage.sh | sudo bash
```

### Memtester

```bash
# Install Memtester
sudo apt install memtester

# Use "size" with the memory capacity you want to allocate (200M)
# And "iteration" with the number of passes or iterations you want to run for testing (1).
sudo memtester 200M 1
```

### Kubernetes

```bash
# Check that you have resolved any Additional OS Preparation
k3s check-config

# Check if system is compatible with longhorn
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/master/scripts/environment_check.sh | bash
```

# SSH

The Secure Shell protocol (SSH) is used to create secure connections between your device and private servers. The connection is authenticated using public SSH keys, which are derived from a private SSH key (also known as a private/public key pair). The secure (encrypted) connection is used to securely establish connection to transfer or run commands on remote devices.

some of the best practices when creating SSH keys are:

* Keys should be issued to individuals, not groups
* Rotating your keys
* Don't use the default comment
* Always use a passphrase

## Generate SH Keys

In order to generate SSH keys you need to run following commands and following best practices.

```bash
# [Optional] If ssh folder does not exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Do not fill anything in next command just enter
ssh-keygen -t rsa -b 4096 -C "jsa4000@gmail.com" -f ~/.ssh/server_key

# [Optional] Copy keys to each node or use AUTO_SETUP_SSH_PUBKEY in 'dietpi.txt' config instead
ssh-copy-id -i ~/.ssh/server_key.pub root@192.168.3.100

```

## Connect

In order to connect to the remote servers you would need to use `ssh` client.

```bash
# [Optional] Remove previous known host for previous connections
rm ~/.ssh/known_hosts

# SSH into the machine (user/password)
ssh root@192.168.3.100

# SSH into the machine (private key)
ssh -i ~/.ssh/server_key root@192.168.3.100
ssh -i ~/.ssh/server_key dietpi@192.168.3.100

# You can run commands using ssh
ssh -i ~/.ssh/server_key dietpi@sbc-server-1 'ls -la'

# You can transfer files between local and server respectively 'scp [source] [destination]'
scp ~/file.txt dietpi@192.168.3.100:~/

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

Connect using `ssh` client and without providing the key.

```bash
# [Optional] Remove previous known host for previous connections
rm ~/.ssh/known_hosts

# SSH using the user@host specified in the SSH config
ssh dietpi@sbc-server-1
ssh dietpi@sbc-server-2
ssh dietpi@sbc-server-3

# You can run commands remotely
ssh dietpi@sbc-server-1 'sudo poweroff'
ssh dietpi@sbc-server-2 'sudo poweroff'
ssh dietpi@sbc-server-3 'sudo poweroff'
```

## SSH Agent

The `ssh-agent` is caching your keys' in memory once these are unlocked and you will not be asked to provide the passphrase to unlock these keys every time they are used.

```bash
# Check if ssh-agent is already running in the machine
ps ax | grep ssh-agent

# Start the agent of not running
eval "$(ssh-agent -s)"
```

Add your SSH private key to the `ssh-agent` and store your passphrase in the keychain.

```bash
# Add ssh to the agent
ssh-add --apple-use-keychain ~/.ssh/server_key
```

The result must be similar to this `~/.ssh/config`, so it can be added manually.

```bash
 Host sbc-server-1
    HostName 192.168.3.100
    User     dietpi
    IdentityFile /Users/jsantosa/.ssh/server_key
    AddKeysToAgent yes
    UseKeychain yes
    IgnoreUnknown UseKeychain

```

#!/bin/bash

# Post-networking and post-DietPi install

# Set fixed MAC Address
sed -i "s|iface eth0 inet static|iface eth0 inet static\nhwaddress ether $SERVER_MAC|g" /etc/network/interfaces

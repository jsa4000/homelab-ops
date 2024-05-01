#!/bin/bash

# Post-networking and post-DietPi install

# Set fixed MAC Address
HWADDRESS_CONFIG="hwaddress ether $SERVER_MAC_ADDRESS"
IFACE_STATIC_CONFIG="iface eth0 inet static"
sed -i "" "s|$IFACE_STATIC_CONFIG|$IFACE_STATIC_CONFIG\n$HWADDRESS_CONFIG|g" /etc/network/interfaces

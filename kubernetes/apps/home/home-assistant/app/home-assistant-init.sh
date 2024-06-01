#!/bin/bash
#set -e
set -a
set -o allexport

echo "------------------------------------------------------------------------"
echo "Initialization Script for Home Assistant"
echo "------------------------------------------------------------------------"
echo

CONFIGURATION_FILE=/config/configuration.yaml
VAR_TO_CHECK=HASS_HTTP_TRUSTED_PROXY_1

echo "Checking if the configuration has been already applied (idempotent)"

cat $CONFIGURATION_FILE | grep -q $VAR_TO_CHECK &>/dev/null
if [ $? -eq 0 ]; then
    echo "Configuration has already been applied"
    return 0
fi

echo "Appling the configuration to Home Assistant"

echo " - Adding proxy exceptions to access from different access points and IP Addresses."

cat <<EOT >> $CONFIGURATION_FILE

http:
  use_x_forwarded_for: true
  trusted_proxies:
    - !env_var HASS_HTTP_TRUSTED_PROXY_1
    - !env_var HASS_HTTP_TRUSTED_PROXY_2
  ip_ban_enabled: true
EOT

echo "Configuration Applied"

#!/bin/bash

# How To use it:
# > source kubernetes/utils/home-assistant-init.sh

# This can be done via kubernetes or use code-server

# Execute follosing command to add proxy exceptions to Home Assistant.
kubectl exec -n home home-assistant-0 -c main -- bash -c "cat <<EOT >> /config/configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - !env_var HASS_HTTP_TRUSTED_PROXY_1
    - !env_var HASS_HTTP_TRUSTED_PROXY_2
  ip_ban_enabled: true
  login_attempts_threshold: 5
EOT"

# Force to Restart Home Assistant
kubectl delete pod -n home home-assistant-0

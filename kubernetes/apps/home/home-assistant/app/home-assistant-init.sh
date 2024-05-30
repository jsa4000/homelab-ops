#!/bin/bash

# Connect via kubernetes or use code-server to add proxy exceptions to Home Assistant.
# > kubectl exec -n home home-assistant-0 -c main -it -- sh

cat <<EOT >> /config/configuration.yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.42.0.0/16
    - 10.52.0.0/16
  ip_ban_enabled: true
  login_attempts_threshold: 5
EOT

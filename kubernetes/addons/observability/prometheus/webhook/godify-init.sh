#!/bin/bash

# Variables
SCHEME_URL=http
GOTIFY_URL=gotify.observability.svc.cluster.local
GOTIFY_PORT=80
GOTIFY_HEALTH_ENDPOINT=/health
GOTIFY_APPICATION_ENDPOINT=/application
CONFIG_FOLDER=/config

# Install utils
apk add curl jq

echo "Wait connecting to Gotify..."
while [ "$(curl -sk -o /dev/null -w '%{http_code}' $SCHEME_URL://$GOTIFY_URL$PORT$GOTIFY_HEALTH_ENDPOINT)" -ne 200 ]; do sleep 10; done

curl -k -u $GOTIFY_USER_NAME:$GOTIFY_USER_PASS $SCHEME_URL://$GOTIFY_URL$PORT$GOTIFY_APPICATION_ENDPOINT \
-F "name=$GOTIFY_APPLICATION_NAME" \
-F "description=$GOTIFY_APPLICATION_DESCRIPTION" \
| jq '.token' > $CONFIG_FOLDER/GOTIFY_TOKEN

printf "Gotify initialized created.\n"
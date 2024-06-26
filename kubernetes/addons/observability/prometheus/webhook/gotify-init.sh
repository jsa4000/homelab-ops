#!/bin/bash

# Variables
SCHEME_URL=http
GOTIFY_URL=gotify.observability.svc.cluster.local
GOTIFY_PORT=80
GOTIFY_HEALTH_ENDPOINT=/health
GOTIFY_APPICATION_ENDPOINT=/application
GOTIFY_TOKEN_ENV=GOTIFY_TOKEN
GOTIFY_SECRET_NAME=gotify-webhook-token
GOTIFY_SECRET_NAMESPACE=observability

# Install utils
# TODO: Use custom immutable image
# apk add curl kubectl jq

echo "Wait connecting to Gotify..."
while [ "$(curl -sk -o /dev/null -w '%{http_code}' $SCHEME_URL://$GOTIFY_URL$PORT$GOTIFY_HEALTH_ENDPOINT)" -ne 200 ]; do sleep 10; done

echo "Check if application $GOTIFY_APPLICATION_NAME has been already created"
RESULT=$(curl -k -s -u $GOTIFY_USER_NAME:$GOTIFY_USER_PASS $SCHEME_URL://$GOTIFY_URL$PORT$GOTIFY_APPICATION_ENDPOINT | jq --arg GOTIFY_APPLICATION_NAME $GOTIFY_APPLICATION_NAME '.[] | select(.name == $GOTIFY_APPLICATION_NAME) | length')
if [ ! -z "$RESULT" ]; then
  echo "Application $GOTIFY_APPLICATION_NAME has already been created";
  exit 0;
fi

echo "Creating application $GOTIFY_APPLICATION_NAME"
GOTIFY_TOKEN=$(curl -k -s -u $GOTIFY_USER_NAME:$GOTIFY_USER_PASS $SCHEME_URL://$GOTIFY_URL$PORT$GOTIFY_APPICATION_ENDPOINT \
-F "name=$GOTIFY_APPLICATION_NAME" \
-F "description=$GOTIFY_APPLICATION_DESCRIPTION" \
| jq -r '.token')

# Create the secret with the generated token
kubectl create secret -n $GOTIFY_SECRET_NAMESPACE generic $GOTIFY_SECRET_NAME \
--from-literal=$GOTIFY_TOKEN_ENV=$GOTIFY_TOKEN

printf "Gotify initialized created.\n"

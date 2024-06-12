#!/bin/bash
#set -e
set -a
set -o allexport

# How To use it:
# > source kubernetes/utils/home-assistant-init.sh

# NOTE: Configuration file can be modifed via kubernetes (kubectl exec -it ..) or using code-server and editing the file manually.

echo "------------------------------------------------------------------------"
echo "Initialization Script for Home Assistant"
echo "------------------------------------------------------------------------"
echo

POD_NAME=home-assistant-0
CONTAINER_NAME=main
NAMESPACE=home
CONFIGURATION_FOLDER=/config
DASHBOARDS_FOLDER=$CONFIGURATION_FOLDER/dashobards
CONFIGURATION_FILE=$CONFIGURATION_FOLDER/configuration.yaml
TEMPLATE_FOLDER=kubernetes/utils/templates/home-assistant/
VAR_TO_CHECK=HASS_HTTP_TRUSTED_PROXY_1

echo "Checking if the configuration has been already applied (idempotent)"

kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- bash -c "cat $CONFIGURATION_FILE | grep -q $VAR_TO_CHECK" &>/dev/null
if [ $? -eq 0 ]; then
    echo "Configuration has already been applied"
    return 0
fi

echo "Appling the configuration to Home Assistant"

echo " - Removing previous configuration"
kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- bash -c "rm -rf $DASHBOARDS_FOLDER" &>/dev/null

echo " - Copying dashboards and patches files to the Home Assistant"
kubectl cp -n $NAMESPACE $TEMPLATE_FOLDER $POD_NAME:$DASHBOARDS_FOLDER -c $CONTAINER_NAME

echo " - Adding proxy exceptions to access from different access points and IP Addresses and dashobards"
kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- bash -c "cat $DASHBOARDS_FOLDER/configuration-patch.yaml >> $CONFIGURATION_FILE" &>/dev/null

# Force to Restart Home Assistant
kubectl delete pod -n $NAMESPACE $POD_NAME

echo
echo "Configuration Applied"

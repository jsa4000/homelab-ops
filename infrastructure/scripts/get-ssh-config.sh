#!/bin/bash
#set -e

# How To use it:
# > source ./scripts/get-ssh-config.sh
# > source ./scripts/get-ssh-config.sh ./clusters/bootstrap/servers.yaml  ~/.ssh/server_key $HOME/.ssh/ssh_config
# > source ./scripts/get-ssh-config.sh $CONFIG_FILE $SSH_KEY_FILE $OUTPUT_FILE
#

CONFIG_FILE=${1:-./clusters/bootstrap/servers.yaml}
SSH_KEY_FILE=${2:-~/.ssh/server_key}
OUTPUT_FILE=${4:-$HOME/.ssh/ssh_config}

TEMPLATE_FILE=./clusters/bootstrap/templates/ssh/config.template

echo "------------------------------------------------------------"
echo "Initialization Script for SSH Config"
echo "------------------------------------------------------------"
echo

yq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: yq tool has been not found."
    return 1
fi

envsubst --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: envsubst tool has been not found."
    return 1
fi

if ! [ -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file does not exist: $CONFIG_FILE"
    return 1
fi

if ! [ -f "$SSH_KEY_FILE" ]; then
    echo "ERROR: SSH key does not exist: $SSH_KEY_FILE"
    return 1
fi

SERVERS=( $(yq -e '.servers | keys | join(" ")' $CONFIG_FILE) )

OUTPUT="\n"
OUTPUT="$OUTPUT # Note: Include this file into  ~/.ssh/config\n"
OUTPUT="$OUTPUT # Use: Include $OUTPUT_FILE\n\n"
for SERVER_NAME in "${SERVERS[@]}"; do

    export SERVER_PATH=.servers.$SERVER_NAME
    export SERVER_INFO=$(yq -e 'eval(strenv(SERVER_PATH))' $CONFIG_FILE)

    if [ $? -ne 0 ] || [[ -z $SERVER_INFO ]]; then
        echo "ERROR: Parsing YAML file: $CONFIG_FILE"
        return 1
    fi

    export SSH_HOST=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .hostname' $CONFIG_FILE)
    export SSH_HOSTNAME=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .ip' $CONFIG_FILE)
    export SSH_USERNAME=$(yq -e '(.. | select(tag == "!!str")) |= envsubst | eval(strenv(SERVER_PATH)) | .user' $CONFIG_FILE)
    export SSH_KEY=$SSH_KEY_FILE

    OUTPUT="$OUTPUT $(envsubst < $TEMPLATE_FILE)\n\n"

done

echo $OUTPUT > $OUTPUT_FILE

echo "In order to apply these changes you will need:"
echo "1. Check the created file at $OUTPUT_FILE with the configuration."
echo "2. Include the create file into global ssh configuration file '~/.ssh/config' and using 'Include $OUTPUT_FILE'"
echo
echo DONE!

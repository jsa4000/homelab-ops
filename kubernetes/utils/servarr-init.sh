#!/bin/bash
#set -e
set -a
set -o allexport

# How To use it:
# > source kubernetes/utils/servarr-init.sh
# > source kubernetes/utils/servarr-init.sh pro

echo "------------------------------------------------------------------------"
echo "Initialization Script for Servarr (Prowlarr, Sonarr, Radarr, etc.)"
echo "------------------------------------------------------------------------"
echo

# Import environment variables
if [ -f ".env" ]; then
    echo Detected dotenv file, loading variables...
    source .env
    echo
fi

ENVIRONMENT=${1:-staging} # pro, staging, cluster
API_KEY=${2:-$SERVARR_APIKEY}

# Internal Network Configuration (LAN)
INTERNAL_PORT=
INTERNAL_SCHEME_URL=https
INTERNAL_DOMAIN=internal.javiersant.com
TEMPLATE_FOLDER=./kubernetes/utils/templates/servarr

# Cluster Network Configuration (kubernetes)
CLUSTER_SCHEME_URL=http
CLUSTER_DOMAIN=media.svc.cluster.local
CLUSTER_PORT=:80

# Configuration
PROWLARR=prowlarr
PROWLARR_URL=http://prowlarr.media.svc.cluster.local:80
PROWLARR_TEMPLATE_FOLDER=$TEMPLATE_FOLDER/$PROWLARR

RADARR=radarr
RADARR_URL=http://radarr.media.svc.cluster.local:80
RADARR_TEMPLATE_FOLDER=$TEMPLATE_FOLDER/$RADARR

SONARR=sonarr
SONARR_URL=http://sonarr.media.svc.cluster.local:80
SONARR_TEMPLATE_FOLDER=$TEMPLATE_FOLDER/$SONARR

QBITTORRENT_HOST=qbittorrent.media.svc.cluster.local
QBITTORRENT_PORT=80

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: jq tool has been not found."
    return 1
fi

envsubst --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: envsubst tool has been not found."
    return 1
fi

# Switch between different environments to be run the script
PORT=$INTERNAL_PORT
SCHEME_URL=$INTERNAL_SCHEME_URL
DOMAIN=$INTERNAL_DOMAIN
if [ "$ENVIRONMENT" = "cluster" ]; then
   SCHEME_URL=$CLUSTER_SCHEME_URL
   DOMAIN=$CLUSTER_DOMAIN
   PORT=$CLUSTER_PORT
elif [ "$ENVIRONMENT" != "pro" ]; then
   DOMAIN=$ENVIRONMENT.$INTERNAL_DOMAIN
fi

echo "Environment: $ENVIRONMENT"
echo "Api Key: $API_KEY"
echo "Domain: $DOMAIN"

echo
echo "Configuring Prowlarr ($SCHEME_URL://$PROWLARR.$DOMAIN$PORT)"
echo

echo -n "Adding Radarr Application -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$PROWLARR.$DOMAIN$PORT/api/v1/applications" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $PROWLARR_TEMPLATE_FOLDER/create-radarr-application-request.json)"

echo -n "Adding Sonarr Application -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$PROWLARR.$DOMAIN$PORT/api/v1/applications" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $PROWLARR_TEMPLATE_FOLDER/create-sonarr-application-request.json)"

# NOTE: Indexes should be added manually for privacy reasons.

echo
echo "Configuring Radarr ($SCHEME_URL://$RADARR.$DOMAIN$PORT)"
echo

echo -n "Adding Radarr Download Clients -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$RADARR.$DOMAIN$PORT/api/v3/downloadclient" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $RADARR_TEMPLATE_FOLDER/create-download-client-request.json)"

echo -n "Adding Radarr RootFolder -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$RADARR.$DOMAIN$PORT/api/v3/rootFolder" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $RADARR_TEMPLATE_FOLDER/create-rootfolder-request.json)"

echo
echo "Configuring Sonarr ($SCHEME_URL://$SONARR.$DOMAIN$PORT)"
echo

echo -n "Adding Sonarr Download Clients -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$SONARR.$DOMAIN$PORT/api/v3/downloadclient" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $SONARR_TEMPLATE_FOLDER/create-download-client-request.json)"

echo -n "Adding Sonarr RootFolder -> "

curl -sk --output /dev/null --write-out '%{http_code}\n' -X POST "$SCHEME_URL://$SONARR.$DOMAIN$PORT/api/v3/rootFolder" \
-H 'Accept: application/json' -H 'Content-Type: application/json' -H "X-Api-Key: $SERVARR_APIKEY" \
--data "$(envsubst < $SONARR_TEMPLATE_FOLDER/create-rootfolder-request.json)"

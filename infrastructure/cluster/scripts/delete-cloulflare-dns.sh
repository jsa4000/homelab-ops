#!/bin/bash
#set -e

# How To use it:
# > source ../../.env
# > source ./scripts/delete-cloulflare-dns.sh $CLOUDFLARE_API_TOKEN $CLOUDFLARE_ZONE_ID

API_TOKEN=$1
ZONE_ID=$2

curl --silent "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?per_page=50000" \
    --header "Authorization: Bearer $API_TOKEN" \
| jq --raw-output '.result[].id' | while read id
do
curl --silent --request DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$id" \
    --header "Authorization: Bearer $API_TOKEN"
done

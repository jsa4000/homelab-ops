#############################################################################################
###      Zitadel Init
#############################################################################################
# Init Script for Zitadel to create initial user, application to be used by Oauth2 Proxy
#
# TODO: Build docker container with immutable versions instead

# Install utils
apk add curl git openssl kubectl

# Install opentofu
OPEN_TOFU_VERSION=1.6.2
OPEN_TOFU_ARCH=arm64
wget https://github.com/opentofu/opentofu/releases/download/v${OPEN_TOFU_VERSION}/tofu_${OPEN_TOFU_VERSION}_${OPEN_TOFU_ARCH}.apk -O tofu.apk
apk add --allow-untrusted tofu.apk

# Clone the repository
# git clone https://github.com/jsa4000/homelab-ops.git
git clone https://${GITHUB_PAT}@github.com/jsa4000/homelab-ops.git
cd homelab-ops/infrastructure/terraform/zitadel/

echo "Wating to connect to Zitadel"

# Get HTTP Status Code
status_code=$(curl -sk -o /dev/null -w "%{http_code}" https://zitadel.javiersant.com/debug/ready)
if [[ "$status_code" -ne 200 ]] ; then
    sleep 5m
fi

echo "Successfully connected to Zitadel"

# Download the certificate
openssl s_client -connect zitadel.javiersant.com:443 -servername zitadel.javiersant.com </dev/null | openssl x509 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > javiersant.com.pem
cp javiersant.com.pem /usr/local/share/ca-certificates/javiersant.com.pem
update-ca-certificates

# Init tofu providers
tofu init -upgrade

# Apply Tofu changes
tofu apply -auto-approve -var jwt_profile_file=/etc/config/zitadel-admin-sa.json

# Create the secret after run OpenTofu
kubectl create secret -n iam generic oauth2-proxy \
--from-literal=client-id=$(tofu output -raw zitadel_application_client_id) \
--from-literal=client-secret=$(tofu output -raw zitadel_application_client_secret) \
--from-literal=cookie-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

echo "Completed."

# End Script

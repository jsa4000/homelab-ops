# OpenTofu

**OpenTofu** is an open-source project that serves as a fork of the legacy MPL-licensed Terraform. It was developed as a response to a change in HashiCorp's licensing of Terraform, from Mozilla Public License (MPL) to a Business Source License (BSL), which imposed limitations on the use of Terraform for commercial purposes. As an alternative, OpenTofu aims to offer a reliable, community-driven solution under the Linux Foundation.

The elements of OpenFou/terraform are:

* **Providers** are essentially **plugins** enabling OpenTofu to interact with various infrastructure **resources**.
* **Resources** in OpenTofu refer to the infrastructure elements that OpenTofu can manage.
* **Data source** in OpenTofu is a configuration element designed to `fetch` data from an external source.

## Install

there are multiple ways yo install OpenTofu, from MacOs the easiest way is to use `Homebrew`.

```bash
# Install using following commands.
brew update
brew install opentofu

# Verify the installation
tofu --version
```

Create an `IngressRoute` with `h2c` scheme to allow provider to connect via grpc in a secure way.

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: zitadel-dashboard
  namespace: iam
  annotations:
    kubernetes.io/ingress.class: traefik-external
    external-dns.alpha.kubernetes.io/target: javstudio.org
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`zitadel.javstudio.org`)
      kind: Rule
      services:
        - kind: Service
          name: zitadel
          scheme: h2c
          passHostHeader: true
          port: 8080
  tls:
    secretName: wildcard-javstudio-org-tls
```

## Structure

Create `versions.tf` and `main.tf` with the providers and versions to enable managing Zitadel resources.

## Execute

Get the `client-key-file` in JSON format created automatically by `ZIDATEL` deployment.

```bash
kubectl get -n iam secrets zitadel-admin-sa -o=jsonpath='{.data.zitadel-admin-sa\.json}' | base64 --decode | jq . > ../service-user-jwt/client-key-file.json
```

Initialize Tofu project to download dependencies

> Install **self-signed** certificates if needed by going to browser, download the `.pem` and installing certificate into `Login` category within `KeyChain Access` tool.

```bash
# Remove previous state
rm terraform.tfs*

# Initialize and upgrade project (migration from Terraform)
tofu init -upgrade
```

Verify the changes to the plan

```bash
# Get the tofu plan
tofu plan

# Debug Traces
TF_LOG="DEBUG" tofu plan
```

Apply the changes

```bash
# Get the tofu plan
tofu apply
```

Get data from outputs

```bash
# Get generated clientId (use '-raw' to get variable without quotes)
tofu output -raw zitadel_application_client_id

# Get generated SecretId
tofu output -raw zitadel_application_client_secret
```

## Local Providers

Copy the generated plugin version compiled (`go build`) using following structure

```txt
 ~/.terraform.d
    └── plugins
        └── local.providers
            └── zitadel
                └── zitadel
                    └── 1.1.1
                        └── darwin_arm64
                            ├── LICENSE
                            ├── README.md
                            └── terraform-provider-zitadel_v1.1.1
```

Add following provider into `versions.tf`

```bash
# Add local provider
terraform {
  required_providers {
    zitadel = {
      source  = "local.providers/zitadel/zitadel"
      version = "1.1.1"
    }
  }
}
```

## Docker

```bash
# Run alpine image
docker run -it --rm alpine:3.19.1

# Install utils
apk add curl git openssl

# Install opentofu
OPEN_TOFU_VERSION=1.6.2
OPEN_TOFU_ARCH=arm64
wget https://github.com/opentofu/opentofu/releases/download/v${OPEN_TOFU_VERSION}/tofu_${OPEN_TOFU_VERSION}_${OPEN_TOFU_ARCH}.apk -O tofu.apk
apk add --allow-untrusted tofu.apk

# Check installed correctly
tofu -v

# Clone the repository
git clone https://github.com/jsa4000/homelab-ops.git
cd homelab-ops/infrastructure/terraform/zitadel/

# Download the certificate
# ls /usr/local/share/ca-certificates/
openssl s_client -showcerts -connect zitadel.javstudio.org:443 -servername zitadel.javstudio.org  </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > javstudio.org.pem
cp javstudio.org.pem /usr/local/share/ca-certificates/javstudio.org.pem
update-ca-certificates

# Init tofu providers
tofu init -upgrade
tofu apply -auto-approve

# Create the secret after run OpenTofu
kubectl create secret -n iam generic oauth2-proxy \
    --from-literal=client-id=$(tofu output -raw zitadel_application_client_id) \
    --from-literal=client-secret=$(tofu output -raw zitadel_application_client_secret) \
    --from-literal=cookie-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
```

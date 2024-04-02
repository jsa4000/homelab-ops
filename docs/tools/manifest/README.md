# README

## Usage

```bash
# Get all pods
kubectl get pods,services -A -o wide

# Create godaddy api key at https://developer.godaddy.com/
export GODADDY_API_KEY=<MY-APY-KEY>
export GODADDY_SECRET_KEY=<MY-SECRET-KEY

# Create Github Crendentials
export GITHUB_REPO=<GITHUB_REPO>
export GITHUB_USERNAME=<GITHUB_USERNAME>
export GITHUB_PASSWORD=<GITHUB_PASSWORD>

# Set environment (copy to root path if desired)
source "/Users/jsantosa/Library/CloudStorage/GoogleDrive-jsa4000@gmail.com/My Drive/Ocio/Cluster/keys/.env"

# Create global secret
kubectl create namespace security
kubectl create secret -n security generic cluster-secrets \
    --from-literal=GODADDY_API_KEY=$GODADDY_API_KEY \
    --from-literal=GODADDY_SECRET_KEY=$GODADDY_SECRET_KEY \
    --from-literal=GITHUB_REPO=$GITHUB_REPO \
    --from-literal=GITHUB_USERNAME=$GITHUB_USERNAME \
    --from-literal=GITHUB_PAT=$GITHUB_PAT

# Add to /etc/hosts
# 192.168.205.200 traefik.javstudio.org grafana.javstudio.org prometheus.javstudio.org longhorn.javstudio.org argocd.javstudio.org zitadel.javstudio.org oauth.javstudio.org

#########################
# Cilium
#########################

# Deploy cilium
kubectl create namespace networking
kubectl kustomize clusters/local/addons/networking/cilium --enable-helm | kubectl apply -f -

# Default configuration
kubectl kustomize kubernetes/addons/networking/cilium --enable-helm | kubectl apply -f -

# Remove cilium
kubectl kustomize kubernetes/addons/networking/cilium --enable-helm | kubectl delete -f -

#########################
# External Secrets
#########################

# Deploy external-secrets
kubectl kustomize kubernetes/addons/security/external-secrets --enable-helm | kubectl apply -f -

# Local
kubectl kustomize clusters/local/addons/security/external-secrets --enable-helm | kubectl apply -f -

# Remove external-secrets
kubectl kustomize kubernetes/addons/security/external-secrets --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n security
kubectl get ClusterSecretStore,SecretStore -n security

#########################
# Deploy Argo-cd
#########################

# Deploy Argo-cd
kubectl create namespace gitops
kubectl kustomize kubernetes/addons/gitops/argocd --enable-helm | kubectl apply -f -

# Create Github Credentials
# https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#repositories
cat <<EOF | kubectl apply -n gitops -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-secret
  namespace: argo-cd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: $GITHUB_REPO
  username: $GITHUB_USERNAME
  password: $GITHUB_PAT
EOF

# Remove Argo-cd
kubectl kustomize kubernetes/addons/gitops/argocd --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n gitops

# Connect to Argocd
kubectl port-forward svc/argocd-server -n gitops 8080:80

# https://argocd.javstudio.org

# Get the "admin" password
kubectl get secret argocd-initial-admin-secret -n gitops -o jsonpath="{.data.password}" | base64 -d

# Apply addons
kubectl apply -f kubernetes/bootstrap/addons-appset.yaml

# NOTE: Sometimes it's needed to go to ArgoCD UI and "Terminate" te Sync and force to Sync again to trigger the creation.

# Specific layer
kubectl apply -n gitops -f kubernetes/addons/gitops/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/kube-system/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/security/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/networking/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/storage/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/database/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/observability/appset.yaml
kubectl apply -n gitops -f kubernetes/addons/iam/appset.yaml

#########################
# Deploy Metallb
#########################

# Deplot Metallb Operator
kubectl apply -k manifests/metallb

# Deploy Metallb Pool (Configuration)
kubectl apply -k manifests/metallb-pool/overlays/local

# Check Metallb Pool overlays (Preview)
# kubectl apply -k manifests/metallb-pool/overlays/home -o yaml
# kubectl apply -k manifests/metallb-pool/overlays/local -o yaml

# Deploy nginx (it will create a load balancer)
kubectl apply -f kubernetes/apps/nginx

# Check the LoadBalancer has been assigned to the service
kubectl get pods,services

# http://192.168.205.210

#########################
# External DNS
#########################

# https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/godaddy.md
# https://github.com/anthonycorbacho/external-dns/blob/master/docs/tutorials/traefik-proxy.md

# Deploy external-dns
kubectl kustomize manifests/external-dns  --enable-helm | kubectl apply -f -

# NOTE: Already created using external-secrets
kubectl create secret -n networking generic external-dns-godaddy \
    --from-literal=GODADDY_API_KEY=$GODADDY_API_KEY \
    --from-literal=GODADDY_SECRET_KEY=$GODADDY_SECRET_KEY

# Remove external-dns
kubectl kustomize manifests/external-dns --enable-helm | kubectl delete -f -
kubectl delete secret -n networking external-dns-godaddy

# Get services deployed
kubectl get pods,services -n networking

# Deploy nginx (it will create a load balancer)
kubectl apply -f manifests/nginx
kubectl delete -f manifests/nginx

# Get logs for external-dns
kubectl logs -n networking -l app=external-dns

#########################
# Dynamic DNS (DDNS)
#########################

# DNS (Domain Name System) Record Types
# A: A stands for Address (IP Address). A records is used to resolve a hostname which corresponds to an IPv4 address
# AAAA: Is equivalent to A record but is AAAA records are used to resolve a domain name which corresponds to an IPv6 address.
# CNAME: Stand for Canonical Name. This record routes the traffic to another domain record, it can be to a A, AAAA, CNAME, etc.. buy it cannot by an IP Address. The CNAME record maps a name to another name. It should only be used when there are no other records on that name. This introduces a performance penalty since at least one additional DNS lookup must be performed to resolve the target (lb.example.net).
# ALIAS: Is similar to CNAME but if differs a bit. The ALIAS record maps a name to another name, but can coexist with other records on that name. The server is the one that perform the lookups so it has better performance that CNAME, but it has it onw drawbacks, for example it loses geo-targeting information.
# NS: Stands for Name Server records. NS records tell the Internet where to go to find out a domain's IP address. If you have the domain purchased in A provider and the DNS are hosted by B provider, in order to resolve the domain and subdomain, you will need to tell to A provider where to lookup, so you need to configure your NS records into the domain provider to point to B provider, with the DNS (authoritative) server.
# SOA: This record (Start of Authority Record) indicates who is responsible for that domain. It contains administrative information about the zone, especially regarding zone transfers, etc..
# TXT: The DNS 'text' (TXT) record lets a domain administrator enter text into the Domain Name System (DNS). The TXT record was originally intended as a place for human-readable notes. However, now it is also possible to put some machine-readable data into TXT records. One domain can have many TXT records. Today, two of the most important uses for DNS TXT records are email spam prevention and domain ownership verification, although TXT records were not designed for these uses originally (SSL Certificates challenges).

# Type      Name  (host     Value (Points To)
# A         @               188.26.209.56       # https://www.myip.com/ https://dnschecker.org/
# CNAME     www             javstudio.org       # Optional
# CNAME     traefik         javstudio.org       # Two lookups to resolve the DNS: traefik.javstudio.org -> javstudio.org -> 188.26.209.56

# NOTE: "@" is short way to specify the same domain @ == javstudio.org

# Home servers or AWS Free Tier EC2 instances generally have dynamic IPv4 address. IP address keep changing when we restart our server or automatically after sometimes. Since, it's not easy to update the DNS record in GoDaddy manually every time IPv4 address changes.
# https://github.com/navilg/godaddy-ddns
# https://hub.docker.com/r/linuxshots/godaddy-ddns

# Deploy godaddy-ddns
kubectl apply -k manifests/godaddy-ddns

# NOTE: Already created using external-secrets
kubectl create secret -n networking generic godaddy-ddns \
    --from-literal=GD_KEY=$GODADDY_API_KEY \
    --from-literal=GD_SECRET=$GODADDY_SECRET_KEY

# Remove godaddy-ddns
kubectl delete -k manifests/godaddy-ddns
kubectl delete secret -n networking godaddy-ddns

# Get services deployed
kubectl get pods,services,cm,secret -n networking

# Get the logs from godaddy-ddns
kubectl logs -n networking -l app=godaddy-ddns -f

#########################
# Deploy Traefik
#########################

# Deploy traeifk
kubectl kustomize kubernetes/addons/networking/traefik-external --enable-helm | kubectl apply -f -

# Remove traeifk
kubectl kustomize kubernetes/addons/networking/traefik-external --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n networking

# Debug
helm template traefik-external /Users/jsantosa/Projects/Github/Mini-Cluster-Setup/manifests/traefik-external/charts/traefik --namespace networking -f ./manifests/traefik-external/values.yaml  --include-crds

# Host file sudo 'code /etc/hosts'
# 192.168.205.200 traefik.local.example.com grafana.local.example.com prometheus.local.example.com
# 192.168.205.200 traefik.javstudio.org grafana.javstudio.org prometheus.javstudio.org

# https://traefik.javstudio.org/

###########################################################################
# Deploy Prometheus Stack ( Prometheus Operator + Prometheus + Grafana )
###########################################################################

# How to Fix "Too long: must have at most 262144 bytes":
# This is because whenever you use kubectl `apply` to create/update resources a `metadata.annotation` is added called `kubectl.kubernetes.io/last-applied-configuration` which is a JSON document that records the last-applied-configuration. Typically this is no issue but in rare circumstances (like large CRDs) it can cause a problem with the apparent size constraint: https://medium.com/pareture/kubectl-install-crd-failed-annotations-too-long-2ebc91b40c7d
# - A workaround for this issue is to use the more imperative kubectl create to create CRDs and kubectl replace to update the CRDs— they do not add this field. Of course you can use apply to create the CRDs and create / update to target the one CRD which is too long.
# - If you are using Kubernetes v1.22 then you can use Server-Side Apply. This is a declarative method which enables different managers to apply different parts of a workload configuration with partial configurations and doesn't use the annotation which is used by Client-Side Apply. https://foxutech.medium.com/how-to-fix-too-long-must-have-at-most-262144-bytes-in-argocd-2a00cddbbe99

# Create Chart
kubectl kustomize manifests/prometheus --enable-helm | kubectl create -f -                # Use create instead apply to avoid error,
kubectl kustomize manifests/prometheus --enable-helm | kubectl apply --server-side -f -   # Another workaround (server-side apply)

# Remove Chart
kubectl kustomize manifests/prometheus --enable-helm | kubectl delete -f -

# Get all pods
kubectl get -n monitoring pods -w
kubectl get -n monitoring pods,services
kubectl edit -n monitoring service prometheus-kube-prometheus-prometheus  # Use loadbalancer or traefik instead (Push from Ceph)

# Deploy MicroCeph monitoring
kubectl apply -k manifests/microceph

# Remove MicroCeph monitoring
kubectl delete -k manifests/microceph

# Get user and password
echo "Username: $(kubectl get -n monitoring secrets kube-prometheus-stack-grafana -o=jsonpath='{.data.admin-user}' | base64 --decode)"
echo "Password: $(kubectl get -n monitoring secrets kube-prometheus-stack-grafana -o=jsonpath='{.data.admin-password}' | base64 --decode)"

# http://localhost:8080 (admin, prom-operator) (2842)
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 8080:80

# http://localhost:9090
kubectl port-forward -n monitoring svc/prometheus-stack-kube-prom-prometheus 9090:9090

# https://prometheus.javstudio.org
# https://grafana.javstudio.org

#########################
# Deploy Reflector
#########################

# Deploy reflector
kubectl kustomize manifests/reflector --enable-helm | kubectl apply -f -

# Remove reflector
kubectl kustomize manifests/reflector --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n kube-system

#########################
# Deploy Cert Manager
#########################

# ACME (Automated Certificate Management Environment) is a standard protocol for automated domain validation and installation of X.509 certificates. Http01 and dns01 ACME challenge methods allows to create certificates automatically, dns support to create wildcard certificates. The DNS-01 challenge is more difficult to automate than HTTP-01, requiring that your DNS provider supply an API for managing your DNS records, since it need to create a TXT record to validate the certificate in the challenge.
# https://www.ssl.com/faqs/which-acme-challenge-type-should-i-use-http-01-or-dns-01/
# There are several circumstances where you might choose DNS-01 over HTTP-01:
#  - If your domain has more that one web server, you will not have to manage challenge files on multiple servers.
#  - DNS-01 can be used even if port 80 is blocked on your web server.

# Beside the default providers supported by cert-manager, there is a list of Webhook providers supported by the community:
# All DNS01 providers will contain their own specific configuration however all require a 'groupName' and 'solverName' field.
# https://github.com/topics/cert-manager-webhook

# Deploy cert-manager
kubectl kustomize kubernetes/addons/kube-system/cert-manager --enable-helm | kubectl apply -f -
kubectl kustomize kubernetes/addons/kube-system/cert-manager/webhooks --enable-helm | kubectl apply -f -
kubectl kustomize kubernetes/addons/kube-system/cert-manager/certs/staging --enable-helm | kubectl apply -f -

# NOTE: Already created using external-secrets
kubectl create secret -n cert-manager generic godaddy-api-key \
    --from-literal=token=$GODADDY_API_KEY:$GODADDY_SECRET_KEY

# Remove cert-manager
kubectl kustomize kubernetes/addons/kube-system/cert-manager --enable-helm | kubectl delete -f -
kubectl kustomize kubernetes/addons/kube-system/cert-manager/webhooks --enable-helm | kubectl delete -f -
kubectl kustomize kubernetes/addons/kube-system/cert-manager/certs/staging --enable-helm | kubectl delete -f -
kubectl delete secret -n cert-manager godaddy-api-key

# Get services deployed
kubectl get pods,services,secrets,configmap -n cert-manager

# Get challenges
kubectl get challenges,Certificates -n cert-manager

# Get the logs from cert-manager
kubectl logs -n cert-manager -l app=cert-manager -f

#########################
# Deploy Longhorn
#########################

# Deploy longhorn
kubectl kustomize manifests/longhorn --enable-helm | kubectl apply -f -

# Remove longhorn
kubectl kustomize manifests/longhorn --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services,storageclass -n storage

# Go to https://longhorn.javstudio.org

#########################
# Deploy Cloud Native PG
#########################

# https://awslabs.github.io/data-on-eks/docs/blueprints/distributed-databases/cloudnative-postgres
# https://github.com/awslabs/data-on-eks/tree/main/distributed-databases/cloudnative-postgres/monitoring

# Deploy Cloud Native PG
kubectl kustomize manifests/cloudnative-pg --enable-helm | kubectl apply -f -
kubectl apply -k manifests/postgres

# Remove Cloud Native PG
kubectl kustomize manifests/cloudnative-pg --enable-helm | kubectl delete -f -
kubectl delete -k manifests/postgres

# Get clusters
kubectl get clusters -n database

# NAME               AGE     INSTANCES   READY   STATUS                     PRIMARY
# postgres-cluster   5m11s   1           1       Cluster in healthy state   postgres-cluster-1

# Get services deployed
kubectl get pods,services -n database

# Services to connect to database depending on the purpose: read, read-only, read-write, etc..
# Usually you would need to connect to read-write service, ie 'service/postgres-cluster-rw'
# NAME                           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
# service/postgres-cluster-r     ClusterIP   10.43.135.93   <none>        5432/TCP   6s
# service/postgres-cluster-ro    ClusterIP   10.43.197.60   <none>        5432/TCP   6s
# service/postgres-cluster-rw    ClusterIP   10.43.96.202   <none>        5432/TCP   6s

# Port forward to test the connection (postgres/password)
kubectl port-forward service/postgres-cluster-rw -n database 5432:5432

# Get certificates created by cert-manager
kubectl get certificates -n database

# Extract certificates created by cert-manager and set into postgres
kubectl get secret postgres-zitadel-client-cert -n iam -o jsonpath='{.data.tls\.key}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/tls.key
kubectl get secret postgres-zitadel-client-cert -n iam -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/tls.crt
kubectl get secret postgres-zitadel-client-cert -n iam -o jsonpath='{.data.ca\.crt}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/ca.crt

kubectl get secret postgres-cluster-superuser-cert -n database -o jsonpath='{.data.tls\.key}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/tls.key
kubectl get secret postgres-cluster-superuser-cert -n database -o jsonpath='{.data.tls\.crt}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/tls.crt
kubectl get secret postgres-cluster-superuser-cert -n database -o jsonpath='{.data.ca\.crt}' | base64 -d > ~/Projects/Github/Mini-Cluster-Setup/tmp/ca.crt

# Get all CRD (Custom Resource Definition) created
kubectl get crds | grep cnpg.io

#########################
# Deploy Zitadel
#########################

# https://github.com/zitadel/zitadel/blob/main/cmd/defaults.yaml

# Deploy Zitadel
kubectl kustomize manifests/zitadel --enable-helm | kubectl apply -f -

# Remove Zitadel
kubectl kustomize manifests/zitadel --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n iam
kubectl get secret,configmap,pod -n iam

# It will create a database called Zitadel within postgres cluster

# Get Secret (zitadel-admin-sa.json)
kubectl get -n iam secrets zitadel-admin-sa -o yaml
kubectl get -n iam secrets zitadel-admin-sa -o=jsonpath='{.data.zitadel-admin-sa\.json}' | base64 --decode | jq .

# OpenTofu
# Go to https://zitadel.javstudio.org and download certificate if not Let's Encrypt production.
# openssl s_client -showcerts -connect zitadel.javstudio.org:443 -servername zitadel.javstudio.org  </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > javstudio.org.pem
# sudo security add-trusted-cert -d -r trustAsRoot -k /Library/Keychains/System.keychain javstudio.org.pem
# rm javstudio.org.pem

cd ~/Projects/Github/Mini-Cluster-Setup/docs/iam/tofu
kubectl get -n iam secrets zitadel-admin-sa -o=jsonpath='{.data.zitadel-admin-sa\.json}' | base64 --decode | jq . > ../service-user-jwt/client-key-file.json
rm terraform.tfs*
tofu init -upgrade
tofu apply -auto-approve

# Create the secret after run OpenTofu
kubectl create secret -n iam generic oauth2-proxy \
    --from-literal=client-id=$(tofu output -raw zitadel_application_client_id) \
    --from-literal=client-secret=$(tofu output -raw zitadel_application_client_secret) \
    --from-literal=cookie-secret=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32)

cd ~/Projects/Github/Mini-Cluster-Setup

# admin/RootPasswors1!
# https://zitadel.javstudio.org
# https://zitadel.javstudio.org/.well-known/openid-configuration

#########################
# Deploy OAuth Proxy
#########################

# https://www.leejohnmartin.co.uk/infrastructure/kubernetes/2022/05/31/traefik-oauth-proxy.html
# https://joeeey.com/blog/selfhosting-sso-with-traefik-oauth2-proxy-part-2/#why-oauth2-proxy
# https://zitadel.com/docs/examples/identity-proxy/oauth2-proxy

# Deploy OAuth Proxy
kubectl kustomize manifests/oauth2-proxy --enable-helm | kubectl apply -f -

# Remove OAuth Proxy
kubectl kustomize manifests/oauth2-proxy --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n iam

# Get logs from Pod
kubectl logs -n iam -l app=oauth2-proxy

# https://oauth.javstudio.org

#########################
# Deploy Loki
#########################

# Deploy Loki
kubectl kustomize manifests/loki --enable-helm | kubectl apply -f -

# Remove Loki
kubectl kustomize manifests/loki --enable-helm | kubectl delete -f -

# Get services deployed
kubectl get pods,services -n logging

#########################
# Rook
#########################

# Deploy Rook Operator (use apply to ignore if namespace has been already created, be care for the previous error in kubernetes because annotation too long)
kubectl kustomize manifests/rook-ceph --enable-helm | kubectl apply -f -

# Get limits and quotas configured for the operator
kubectl -n rook-ceph get configmap -w
kubectl describe -n rook-ceph cm rook-ceph-operator-config

# Wait until the operator is ready
kubectl -n rook-ceph get pod -w
kubectl -n rook-ceph get services
kubectl -n rook-ceph get cm,secrets
kubectl top pods -n rook-ceph

# Create the Rook Ceph cluster (external). Secrets from external cluster must be created previously.
kubectl kustomize manifests/external-ceph-cluster --enable-helm | kubectl apply -f -

# Go to dashboard: https://192.168.205.101:8443

# Create Rook Ceph cluster (managed)

# Tear Down Rook from previous installation
# https://rook.io/docs/rook/latest-release/Getting-Started/ceph-teardown/
sudo rm -rf /var/lib/rook
DISK="/dev/mapper/ubuntu--vg-lv1"
sudo dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
sudo sgdisk --zap-all $DISK

# NOTE: It requires 8GiB and 8CPUs to initialize properly, to check the reservations request and limits per node)
# k describe node server-2
kubectl kustomize manifests/rook-ceph-cluster --enable-helm | kubectl apply -f -

# Connect to dashboard (admin/..)
kubectl port-forward -n rook-ceph svc/rook-ceph-mgr-dashboard 7000:7000
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

# If not using Helm Storage Classes and other resources must be created for Block, NFS and Object Storage support
# Create a Storage Pools, Storage Classes and COSI (bject Storage Management) for Ceph using Rook.
kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/deploy/examples/csi/rbd/storageclass.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/deploy/examples/filesystem.yaml
kubectl apply -f https://raw.githubusercontent.com/rook/rook/master/deploy/examples/csi/cephfs/storageclass.yaml

# Check available StorageClasses created
kubectl -n rook-ceph get storageclass

# Check if the cluster is Connected
kubectl get -n rook-ceph CephCluster,CephFilesystem,CephObjectStore

# You can set the default one if set multiple StorageClasses
kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Get running pods
kubectl -n rook-ceph get pod -w
kubectl -n rook-ceph get secrets,cm

# Get resources from nodes
kubectl top node

# Get secrets info
kubectl get -n rook-ceph secret rook-ceph-mon -o yaml

#########################
# Persistent Volumes
#########################

# Kubernetes Volume Types:
# - Block Devices (RBD, LOOP, LVM, etc..) -> ReadWriteOnce
# - FileSystem Data (NFS) -> ReadWriteMany
# - COSI (Container Object Storage Interface) (S3, GCS,  Minio, etc..)

# kubectl create -k github.com/kubernetes-sigs/container-object-storage-interface-api

# Create Stateful Set
kubectl apply -f manifests/stateful-set

# Check whether the volumes has been created and bind
kubectl get pod -w
kubectl get pod,pvc,pv

# Ceph Tools from kubernetes (sudo access)
CEPH_TOOL_POD=$(kubectl get pod -n rook-ceph -l app=rook-ceph-tools | awk '{print $1}' | tail -n +2)
kubectl exec -it -n rook-ceph $CEPH_TOOL_POD -- bash

# ceph health mute  POOL_NO_REDUNDANCY

# Copy file to volumes types (restart the pod)
kubectl cp README.md k8s-summit-demo-0:/data
kubectl cp README.md k8s-summit-demo-0:/usr/share/nginx/html

# Kill the pod and check the file is there
kubectl delete pod k8s-summit-demo-0
kubectl exec -it k8s-summit-demo-0 -- ls /usr/share/nginx/html

# Check the FileSystem to be replicated over other pods
kubectl exec -it k8s-summit-demo-0 -- ls /data
kubectl exec -it k8s-summit-demo-1 -- ls /data
kubectl exec -it k8s-summit-demo-2 -- ls /data

# Get secrets anc configmaps created by the objectbucket resource (cosi)
kubectl get cm,secrets

# config-map, secret, OBC will part of default if no specific name space mentioned
export AWS_HOST=$(kubectl -n default get cm ceph-delete-bucket -o jsonpath='{.data.BUCKET_HOST}')
export PORT=$(kubectl -n default get cm ceph-delete-bucket -o jsonpath='{.data.BUCKET_PORT}')
export BUCKET_NAME=$(kubectl -n default get cm ceph-delete-bucket -o jsonpath='{.data.BUCKET_NAME}')
export AWS_ACCESS_KEY_ID=$(kubectl -n default get secret ceph-delete-bucket -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 --decode)
export AWS_SECRET_ACCESS_KEY=$(kubectl -n default get secret ceph-delete-bucket -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 --decode)

# Install s5cmd
brew install peak/tap/s5cmd

# Upload a file to the newly created bucket
echo "Hello Rook" > /tmp/rookObj
s5cmd --endpoint-url http://$AWS_HOST:$PORT cp /tmp/rookObj s3://$BUCKET_NAME

# Download and verify the file from the bucket
s5cmd --endpoint-url http://$AWS_HOST:$PORT cp s3://$BUCKET_NAME/rookObj /tmp/rookObj-download
cat /tmp/rookObj-download

#########################
# Other
#########################

# Get all pods
kubectl get pods -A
kubectl get pods,services -A -o wide
kubectl get pods,services -A --show-labels

# Get all namespaces
kubectl get namespaces

# Crean Failed Pods
kubectl delete pods --field-selector status.phase=Failed -A

# Test the IP Address metallb has assigned to nginx service (EXTERNAL-IP)
http://192.168.3.200
http://192.168.205.200

# Get Cluster Memory
kubectl top nodes
kubectl describe node server-1
kubectl describe node server-2
kubectl describe node server-3

kubectl top pods -A

# This project can be installed with Krew:
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
kubectl krew install resource-capacity

kubectl resource-capacity --util
kubectl resource-capacity --pods --util

# Get process running in node (Hold Shift + H to group by application)
htop
```

```bash
# Execute DDNS using Goddady API

# For linux running on amd64/arm
docker run \
    --env GD_NAME=@ \
    --env GD_DOMAIN=javstudio.org \
    --env GD_TTL=600 \
    --env GD_KEY=$GODADDY_API_KEY \
    --env GD_SECRET=$GODADDY_SECRET_KEY \
    linuxshots/godaddy-ddns:1.1.1
```

## Port Forward Mac

There is a list of required information that we need, to port forward to Mac. These information details include:

1. The first thing you need to do is find out what your router's IP address is. To do this, go to your router's configuration page and look for the IP address.

   * Open your web browser using the router IP address or router gateway. (i.e `http://192.168.3.1`)
   * Provide your credentials, username, and password.
   * Go to the port forwarding section from the settings.
   * Enter the IP address, TCP, and UDP in their relevant fields.
   * Now restart the router to make changes effective.

2. The IP address of the device to connect.
3. Port forward:
   * ssh: `ssh -L 8443:127.0.0.1:443 ubuntu@192.168.205.200`
   * pf:

```bash
# https://medium.com/@ginurx/how-to-set-port-forwarding-for-internet-sharing-on-mac-os-x-using-pf-a7a338f09953

# Check whether is enabled or disabled
# In System Preferences / Security & Privacy / Firewall Options..., check "Enable stealth mode" and turn on Firewall.
sudo pfctl -s info | egrep -i --color=auto 'enabled|disabled'

# Append to /etc/pf.conf
sudo code /etc/pf.conf
cat /etc/pf.conf

# Added Port-forward (empty line and the end is required)
anchor "org.javstudio/*"
load anchor "org.javstudio" from "/etc/pf.anchors/org.javstudio"

# Create /etc/pf.anchors/org.javstudio
sudo touch /etc/pf.anchors/org.javstudio
sudo code /etc/pf.anchors/org.javstudio
cat /etc/pf.anchors/org.javstudio

# Port forward from localhost to VM
# # ifconfig -a | awk '/^bridge/ {print; while(getline) { if ($0 ~ /^[ \t]/) print; else break; }}' | grep -E "^bridge|inet |status"

#rdr pass on en0 inet proto tcp from any to any port 8443 -> 192.168.205.200 port 443
rdr on en0 inet proto tcp to any port 8443 -> 192.168.205.200 port 443
# rdr pass on en0 inet proto tcp from 192.168.205.200 to any port 443 -> 127.0.0.1 port 8443
# rdr on bridge100 inet proto tcp from 192.168.205.200 to any port 443 -> 127.0.0.1 port 8443

# Second redirect now incoming traffic to localhost 8080 for all traffic that matches our host and port filter
rdr on en0 proto tcp from en0 to any port { 80, 443, 8080, 8443 } -> 127.0.0.1 port 8443
# First route all outgoing traffic from en0 to lo0 that matches our host and port filter and user
pass out on en0 route-to lo0 proto tcp from en0 to <IP to redirect to proxy> port { 80, 443 } keep state user { <user id you are running your browser under> }

# load the new rules
sudo pfctl -f /etc/pf.conf

# Check the rules
sudo pfctl -a org.javstudio -sn

# Disable org.javstudio anchor
sudo pfctl -a org.javstudio -F all

# Ensure that IP forwarding is enabled:
sudo sysctl -w net.inet.ip.forwarding=1

# To verify that IP forwarding is enabled, you can use:
sudo sysctl -a | grep net.inet.ip.forwarding

# Chek rules loaded
sudo pfctl -s rules
sudo pfctl -s References
```

```bash
NGINX_VERSION=1.12.2
mkdir -p ./tmp
cd ./tmp
curl -OL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar -xvzf nginx-$NGINX_VERSION.tar.gz && rm nginx-$NGINX_VERSION.tar.gz
mv nginx-$NGINX_VERSION nginx

# Set Redirect rues
..
```

```bash
# Install socat
brew install socat

# Redirect incoming 8443 traffic to 192.168.205.200:443
sudo socat TCP-LISTEN:8443,fork TCP:192.168.205.200:443

# 1. Ensure firewall allow for incoming traffic
# 2. Enable port in Router/firewall (Port Trigger) and use Port Forwarding for the Machine (NAT)
# 3. Ensure port forwarding is enabled
#   - Option1: sudo cat /proc/sys/net/ipv4/ip_forward
#   - Option2: sudo sysctl -a | grep net.inet.ip.forwarding
# 4. Ensure the Network provider allow you to enable port (https://ping.eu/port-chk/)
```

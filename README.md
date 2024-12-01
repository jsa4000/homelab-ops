<div align="center">

# Homelab

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/jsa4000/homelab-ops/blob/main/LICENSE/ "License")
[![Docs](https://img.shields.io/static/v1.svg?color=009688&labelColor=555555&logoColor=ffffff&label=Homelab&message=Docs&logo=readthedocs)](https://jsa4000.github.io/homelab-ops/ "Documentation for this repository.")
[![GitHub stars](https://img.shields.io/github/stars/jsa4000/homelab-ops?color=green)](https://github.com/jsa4000/homelab-ops/stargazers "This repo star count")
[![GitHub last commit](https://img.shields.io/github/last-commit/jsa4000/homelab-ops?color=purple)](https://github.com/jsa4000/homelab-ops/commits/main "Commit History")
[![OS](https://img.shields.io/badge/Ubuntu-22.04-important&logo=ubuntu)](https://releases.ubuntu.com/22.04/ "Ubuntu 22.04 Jelly")
[![Kubernetes Distribution](https://img.shields.io/badge/Kubernetes-k3s-informational&logo=kubernetes)](https://k3s.io/ "k3s")
[![Release](https://img.shields.io/github/v/release/jsa4000/homelab-ops&logo=semanticrelease)](https://github.com/jsa4000/homelab-ops/releases "Repo releases")
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&logo-pre-commit)](https://github.com/pre-commit/pre-commit "Precommit status")
[![Schedule - Renovate](https://img.shields.io/github/actions/workflow/status/jsa4000/homelab-ops/schedule-renovate.yaml?label=Renovate&logo=renovatebot&branch=main)](https://github.com/Truxnell/home-cluster/actions/workflows/schedule-renovate.yaml)
[![Super-Linter](https://github.com/jsa4000/homelab-ops/actions/workflows/linter.yaml/badge.svg)](https://github.com/marketplace/actions/super-linter)

</div>

---

## :book:&nbsp; Overview

A repository to create a cluster to be used as homelab.

## :wrench:&nbsp; Tools

Below are some of the tools I find useful.

| Tool                                                            | Purpose                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| [ansible](https://github.com/ansible/ansible)                   | Configuration management tool and simple IT automation system                        |
| [Renovate](https://github.com/renovatebot/renovate)             | Automatically finds new releases for the applications and issues corresponding PR's  |
| [TaskFile](https://github.com/go-task/task)                     | Task runner/build tool that aims to be simpler and easier to use than GNU Make.      |
| [pre-commit](https://github.com/pre-commit/pre-commit)          | A framework for managing and maintaining multi-language pre-commit hooks.            |
| [kubesearch](https://kubesearch.dev/)                           | Look for how other people manage their Self-hosted software on k8s-at-home community |
| [mkdocs material](https://squidfunk.github.io/mkdocs-material/) | Static website generator for all my docs in this repo                                |
| [Age](https://github.com/FiloSottile/age)                       | Simple, modern and secure file encryption tool, format, and Go library.              |
| [yamlfmt](https://github.com/google/yamlfmt)                    | Extensible command line tool or library to format yaml files.                        |
| [prettier](https://github.com/prettier/prettier)                | Opinionated code formatter, that enforces a consistent style                         |
| [markdownlint](https://github.com/DavidAnson/markdownlint)      | Static analysis tool to enforce standards and consistency for Markdown files.        |
| [super-linter](https://github.com/super-linter/super-linter)    | A collection of linters and code analyzers, to help validate your source code.       |

### Pre-Commit

Installation can be made using `pip install` or a package manager such as `homebrew`.

```bash
# Install via homebrew
brew install pre-commit
```

Install the `git-hooks` scripts, be sure `.pre-commit-config.yaml` configuration fle has been created in the root folder.

```bash
# Install
pre-commit install
```

Now `pre-commit` will run automatically on `git commit`.

### MkDocs

Installation can be made using `pip install` or a package manager such as `homebrew`.

```bash
# Install via homebrew
brew install mkdocs
```

Initialize a project using `mkdocs`

```bash
# Create a mkdocs project
mkdocs new .
```

Install `MkDocs` plugin dependencies

```bash
# Install dependencies (use --break-system-packages or create python environment)
pip3 install -r .github/mkdocs/requirements.txt --break-system-packages
```

Serve the website content on a local server

```bash
mkdocs serve

# Serve using specific config file location
mkdocs serve -f .github/mkdocs/mkdocs.yml
```

### Renovate

Go to [Renovate](https://github.com/apps/renovate) install the app into the account.

### TaskFile

Task offers many installation methods, so package manager such as `homebrew` can be used.

```bash
# Install via homebrew
brew install go-task
```

Get all current tasks

```bash
# List all available task to run
task -l

# 'task -l' can be set as default task tu run
task

 # Combination of task for initialization
task init
```

Setup `pre-commit` using TaskFile.

```bash
# Init pre-commit hooks
task precommit:init

# Update pre-commit dependencies
task precommit:update
```

Check linting and formatting before commit.

```bash
# Format and Lint
task format:all
task lint:all
```

Run following task to install dependencies using `homebrew`

```bash
# Run 'init' task within brew include file.
task brew:init
```

```bash
# Install ansible dependencies
task ansible:init

# Check the inventory server statuses (staging)
task ansible:ping ANSIBLE_INVENTORY_ENV=staging

# Install kubernetes (staging)
task ansible:install ANSIBLE_INVENTORY_ENV=staging

# Merge Kube config
task ansible:config ANSIBLE_INVENTORY_ENV=staging

# Uninstall Kubernetes (staging)
task ansible:uninstall ANSIBLE_INVENTORY_ENV=staging
```

### Super-Lint

You can run `super-linter` outside GitHub Actions.

```bash
# Run docker image using linux/amd64, since there is no arm64 support.
docker run \
  -e DEFAULT_WORKSPACE=/tmp/lint \
  -e LOG_LEVEL=DEBUG \
  -e RUN_LOCAL=true \
  -e SHELL=/bin/bash \
  -e DEFAULT_BRANCH=main \
  -e ANSIBLE_DIRECTORY=infrastructure/ansible \
  -e VALIDATE_ALL_CODEBASE=true \
  -e VALIDATE_YAML=true \
  -e VALIDATE_MARKDOWN=true \
  -e VALIDATE_JSON=true \
  -e VALIDATE_TERRAFORM_TFLINT=true \
  -e VALIDATE_RENOVATE=true \
  -e YAML_CONFIG_FILE=.yamllint.yaml \
  -v $PWD:/tmp/lint \
  --platform linux/amd64 \
  ghcr.io/super-linter/super-linter:slim-v6.3.0
```

## Installation

### Pre-requisites

#### Environment file

Environment file will be used to store secrets that will be used during the **installation** process and later by **external secret**.

Following file must be created at the root `.env`.

```txt
# NOTE: Apply the changes into the cluster after a modification
# kubectl create secret generic -n security cluster-secrets --from-env-file=.env --dry-run=client -o yaml | kubectl apply -f -

# Goddady API KEY
GODADDY_API_KEY=
GODADDY_SECRET_KEY=

# Cloudfare API TOKEN
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ZONE_ID=

# Github User Name
GITHUB_REPO=https://github.com/jsa4000/homelab-ops.git
GITHUB_USERNAME=
GITHUB_PAT=

# Zitadel MasterKey
# LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 32
ZITADEL_MATERKEY=

# Homelab Password
HOMELAB_USER=
HOMELAB_PASSWORD=

# Postgres Password
POSTGRES_SUPER_PASS=
POSTGRES_USER_PASS=

# Argocd Password (Bcrypt hashed admin password)
# htpasswd -nbBC 10 "" $HOMELAB_PASSWORD  | tr -d ':\n' | sed 's/$2y/$2a/'
ARGOCD_PASSWORD=

# Servarr API key (prowlarr, radarr, sonarr, etc..)
SERVARR_APIKEY=

# Zigbee
# To create a new random network key use: 'shuf -i 0-255 -n 16 | paste -sd "," -'
ZIGBEE2MQTT_NETWORK_KEY=[]

# SpeedTest Tracker API key
# https://speedtest-tracker.dev/
SPEEDTEST_APP_KEY='base64:'

```

#### Clean DNS Records

In order to initialize the cluster, use this script to clean all DNS records from Cloudflare.

> Running this script the new DNS records created will be take some time until it will be replicated over the network (DNS servers)

```bash
# Source environment file into current session
source .env

# Go to infrastructure/cluster/scripts folder
cd infrastructure/cluster/scripts

# Run following script to clean all DNS records.
source ./scripts/delete-cloulflare-dns.sh $CLOUDFLARE_API_TOKEN $CLOUDFLARE_ZONE_ID
```

### Create Cluster (Staging)

Create local cluster where the home-lab will be installed.

> The staging cluster will be at 192.168.205.1XX

```bash
# Go to infrastructure/cluster/scripts folder
cd infrastructure/cluster/scripts

# Run script to create cluster scripts (check resources such as memory, cpu, storage and output folder)
./scripts/create-qemu-cluster.sh

# Follow the instruction to setup the cluster
```

### Addons

#### Run Ansible playbook

Install ansible dependencies and bootstrap the `addons` cluster with core services.

```bash
# Go to infrastructure/ansible folder
cd infrastructure/ansible

# Install ansible dependencies
task ansible:init

# Check hosts are available (use staging or pro)
task ansible:ping ANSIBLE_INVENTORY_ENV=staging

server-2 | SUCCESS => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3"},"changed": false,"ping": "pong"}
server-1 | SUCCESS => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3"},"changed": false,"ping": "pong"}
server-3 | SUCCESS => {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python3"},"changed": false,"ping": "pong"}

# Run ansible using staging inventory file (use staging or pro)
task ansible:install ANSIBLE_INVENTORY_ENV=staging

PLAY RECAP **********************************************************************************************************************************************************************************
server-1                   : ok=67   changed=28   unreachable=0    failed=0    skipped=60   rescued=0    ignored=0
server-2                   : ok=40   changed=12   unreachable=0    failed=0    skipped=53   rescued=0    ignored=0
server-3                   : ok=40   changed=12   unreachable=0    failed=0    skipped=53   rescued=0    ignored=0
```

#### Checklist

Following the checklist to be fulfilled after the ansible initialization.

- [ ] All pods are running in all namespaces (*).
- [ ] Ensure all applications are synced in argocd.
- [ ] Oauth2-proxy is degraded.
- [ ] Internal and external ingresses can be accesses.
- [ ] Check all the volumes are created and used.
- [ ] Check all the targets in Prometheus dashboard are healthy.

> (*) Some applications are intended to be in error or pending states.

##### All pods are running in all namespaces

The bootstrap process can take **some minutes or hours** depending on the internet connection. Wait until all the pods are in `Running` status.

> There are some pods such as  `oauth2-proxy` that you should do manual task to deploy it successfully. Sometimes the status will be `CreateContainerConfigError`.

In order to check the status of the pods, you can use `kubectl` commands.

```bash
# Switch to current cluster kubernetes config (use staging or pro)
task ansible:config ANSIBLE_INVENTORY_ENV=staging

# Get all running pods in all namespaces (k is an alias of kubectl)
k get pods -A

NAMESPACE       NAME                                                    READY   STATUS                       RESTARTS      AGE
database        cnpg-cloudnative-pg-64bb9df9c8-fr95h                   1/1     Running                      0             72m
database        postgres-1                                             1/1     Running                      0             65m
database        postgres-tls-1                                         1/1     Running                      0             61m
gitops          argocd-application-controller-0                        1/1     Running                      0             5m31s
```

##### Ensure all applications are in-sync in argocd

Check all applications deployed in addons cluster are in-sync.

```bash
# Run following command to open argocd dashboard at http://localhost:8080 (admin,**)
task k8s:argocd

# Once traefik and cert-manager are running argocd dashboard can be accessed through 'https://argocd.staging.internal.javiersant.com/'
```

##### OutOfSync - Waiting for completion

**Hooks** in argocd sometimes are not triggered properly, so it get hangs infinitely. In order to solve this issue:

- Go into the apps that are in this state.
- Go into the `Syncing` option and click **TERMINATE**.
- Press **Sync** button again and wait.

> Applications that sometimes get stuck are **argocd** and **zitadel**

##### Oauth2-proxy is degraded

**Oauth2-proxy** can be `degraded` because **Zitadel** was not properly initialized or because a **timeout** trying to access **Zitadel URL**.

Zitadel URL is available when:

- Zitadel DNS record is already created. i.e [https://zitadel.staging.internal.javiersant.com](https://zitadel.staging.internal.javiersant.com)
- Zitadel app (pod) is in `Running` status. (`kubectl get deployment zitadel -n iam`)
- `Cert-manager` has created the certificate. i.e. *.javiersant.com

Once all points above are checked, you must:

- Go to argocd dashboard and search for `oauth2-proxy` application.
- Delete the Job called `oauth2-proxy-zitadel-init` and wait until it completes.
- Wait until `oauth2-proxy` application is properly synced.

##### Internal and external ingresses can be accesses

Check following dashboards to check if everything is working fine.

- [ArgoCD](https://argocd.staging.internal.javiersant.com)
- [Longhorn](https://longhorn.staging.internal.javiersant.com/)
- [Prometheus](https://prometheus.staging.internal.javiersant.com/)
- [Grafana](https://grafana.staging.internal.javiersant.com/)
- [Gotify](https://gotify.staging.internal.javiersant.com/#/)
- [Falco](https://falcosidekick.staging.internal.javiersant.com/)
- [Hubble](https://hubble.staging.internal.javiersant.com/)
- [Kyverno](https://kyverno.staging.internal.javiersant.com/)

### Apps

#### Bootstrap

Bootstrap the `apps` cluster to install additional services and tools.

> This process can take some minutes.

```bash
# Run following command
kubectl apply -f https://raw.githubusercontent.com/jsa4000/homelab-ops/refs/heads/staging/kubernetes/bootstrap/apps-appset.yaml
```

#### Home Assistant

Add Home Assistant configuration to be **access through proxy**, **connect to a database** and **create custom dashboards**.

```bash
# Execute following command from root ./
source kubernetes/utils/home-assistant-init.sh
```

#### Servarr

This will configure the Servarr stack (**Prowlarr**, **Radarr** and **Sonarr**)

```bash
# Execute following command from root ./
# Use staging or pro
source kubernetes/utils/servarr-init.sh staging
```

The go to following steps:

- Add indexer to [Prowlarr](https://prowlarr.staging.internal.javiersant.com/). (public)
- Search for film at [Radarr](https://radarr.staging.internal.javiersant.com/). Use **interactive Search** to search custom one.
- Go to [qbittorrent](https://qbittorrent.staging.internal.javiersant.com/) to check if it's being downloaded.
- Go to [Jellyfin](https://jellyfin.staging.internal.javiersant.com/), create a new account (`admin`) and create a new **Movies** Media folder from `/downloads/movies`.

#### Checklist

Following the checklist to be fulfilled after the ansible initialization.

- [ ] All pods are running in all namespaces (*).
- [ ] Ensure all applications are synced in argocd.
- [ ] Internal and external ingresses can be accesses.
- [ ] Homepage Widgets are showing information.

> (*) Some applications are intended to be in error or pending states.

##### Internal and external ingresses can be accesses

Check following dashboards to check if everything is working fine.

- [Homepage](https://homepage.staging.internal.javiersant.com)
- [IT-Tools](https://it-tools.staging.internal.javiersant.com/)
- [PGAdmin](https://pgadmin.staging.internal.javiersant.com/) [admin@example.com]
- [Redis Commander](https://redis-commander.staging.internal.javiersant.com/) (admin)
- [Speed Test](https://speedtest.staging.internal.javiersant.com/) [admin@example.com]
- [Home Assistant](https://speedtest.staging.internal.javiersant.com/) (Create user at start, admin)
- [Prowlarr](https://prowlarr.staging.internal.javiersant.com/)
- [Radarr](https://radarr.staging.internal.javiersant.com/)
- [QBittorrent](https://qbittorrent.staging.internal.javiersant.com/)
- [File Browser](https://filebrowser.staging.internal.javiersant.com)
- [Jellyfin](https://jellyfin.staging.internal.javiersant.com/) (Create user at start, admin)
- [Open WebUI](https://open-webui.staging.internal.javiersant.com/)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=jsa4000/homelab-ops&type=Date)](https://star-history.com/#jsa4000/homelab-ops&Date)

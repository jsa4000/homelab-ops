# DevPod

DevPod is a client-only tool to create reproducible developer environments based on a [devcontainer.json](https://containers.dev/) on any backend. Each developer environment runs in a container and is specified through a [devcontainer.json](https://containers.dev/). Through DevPod providers, these environments can be created on any backend, such as the local computer, a Kubernetes cluster, any reachable remote machine, or in a VM in the cloud.

![Codespaces](https://github.com/loft-sh/devpod/blob/main/docs/static/media/codespaces-but.png?raw=true)

You can think of DevPod as the glue that connects your local IDE to a machine where you want to develop. So depending on the requirements of your project, you can either create a workspace locally on the computer, on a beefy cloud machine with many GPUs, or a spare remote computer. Within DevPod, every workspace is managed the same way, which also makes it easy to switch between workspaces that might be hosted somewhere else.

![DevPod Flow](https://github.com/loft-sh/devpod/blob/main/docs/static/media/devpod-flow.gif)

## Why DevPod?

DevPod reuses the open [DevContainer standard](https://containers.dev/) (used by GitHub Codespaces and VSCode DevContainers) to create a consistent developer experience no matter what backend you want to use.

Compared to hosted services such as Github Codespaces, JetBrains Spaces, or Google Cloud Workstations, DevPod has the following advantages:

* **Cost savings**: DevPod is usually around 5-10 times cheaper than existing services with comparable feature sets because it uses bare virtual machines in any cloud and shuts down unused virtual machines automatically.
* **No vendor lock-in**: Choose whatever cloud provider suits you best, be it the cheapest one or the most powerful, DevPod supports all cloud providers. If you are tired of using a provider, change it with a single command.
* **Local development**: You get the same developer experience also locally, so you don't need to rely on a cloud provider at all.
* **Cross IDE support**: VSCode and the full JetBrains suite is supported, all others can be connected through simple ssh.
* **Client-only**: No need to install a server backend, DevPod runs only on your computer.
* **Open-Source**: DevPod is 100% open-source and extensible. A provider doesn't exist? Just create your own.
* **Rich feature set**: DevPod already supports prebuilds, auto inactivity shutdown, git & docker credentials sync, and many more features to come.
* **Desktop App**: DevPod comes with an easy-to-use desktop application that abstracts all the complexity away. If you want to build your own integration, DevPod offers a feature-rich CLI as well.

In order to get started with DevPod, you can choose between the **DevPod Desktop application** and **DevPod CLI**.

## CLI

**DevPod CLI** can be very useful to control DevPod from a terminal.

### Installation

Select one of the installation methods available [here](https://devpod.sh/docs/getting-started/install#optional-install-devpod-cli).

```bash
# MacOS Silicon/ARM
curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-darwin-arm64" && \
sudo install -c -m 0755 devpod /usr/local/bin && \
rm -f devpod
```

### Providers

The DevPod team maintains [providers](https://devpod.sh/docs/managing-providers/add-provider) for popular services such as Docker, kubernetes, SSH, AWS, Google Cloud, Azurem etc..

These providers can be installed with the DevPod CLI using following commands.

```bash
# List of available providers
devpod provider list-available

# Docker provider
devpod provider add docker

# Kubernetes provider
devpod provider add kubernetes

# Installed providers
devpod provider list
```

### Workspace

Afterwards you can start by creating workspaces. Microsoft providers a variety of samples projects to test devcontainers [vscode-remote-try-*](https://github.com/search?q=org%3Amicrosoft+vscode-remote-try-&type=Repositories).

> For kubernetes provider it will create a namespace called `devpod`

```bash

# Start in VS Code browser (Node)
devpod up github.com/microsoft/vscode-remote-try-node --ide openvscode

# Start in VS Code (Node)
devpod up github.com/microsoft/vscode-remote-try-node --ide vscode

# Start in VS Code (Go)
devpod up github.com/microsoft/vscode-remote-try-go --ide vscode

# Start in IntelliJ (Java)
# NOTE: JetBrains Gateway is required
devpod up github.com/microsoft/vscode-remote-try-java --ide intellij

# Start without IDE (Node)
devpod up github.com/microsoft/vscode-remote-try-node --ide none

# DevPod IDE commands
devpod ide list

# Get Pods in devpod namespace
kubectl get pods -n devpod
```

Useful Commands

```bash
# Shows the status of a workspace
devpod status

# Lists existing workspaces
devpod list


             NAME          |                         SOURCE                          | MACHINE |  PROVIDER  |   IDE    | LAST USED |  AGE
  -------------------------+---------------------------------------------------------+---------+------------+----------+-----------+---------
    vscode-remote-try-java | git:https://github.com/microsoft/vscode-remote-try-java |         | kubernetes | intellij | 2m15s     | 2m15s
    vscode-remote-try-node | git:https://github.com/microsoft/vscode-remote-try-node |         | kubernetes | vscode   | 23m44s    | 26m27s

# Reconnect to the workspace already created
devpod up vscode-remote-try-node --ide vscode

# Starts a new ssh session-only to a workspace
devpod ssh vscode-remote-try-java

# Deletes an existing workspace
devpod delete vscode-remote-try-java

# Get Pods
kubectl get pods -n devpod
```

## devcontainer.json

**DevPod** uses the open `devcontainer.json` standard to allow users to customize their development containers. Development containers are Docker containers that provide a user with a fully featured development environment. Within DevPod, this container is created based on the underlying provider either locally, in a remote virtual machine or even in a Kubernetes cluster. DevPod makes sure that no matter where you use this configuration the developer experience stays the same.

```json
{
  "name": "Java",
  "image": "mcr.microsoft.com/devcontainers/java:1-21",
  "features": {
    "ghcr.io/devcontainers/features/java:1": {
      "version": "none",
      "installMaven": "true",
      "mavenVersion": "3.8.6",
      "installGradle": "false"
    }
  },
  "customizations": {
    "vscode": {
      "settings": {},
      "extensions": [
        "streetsidesoftware.code-spell-checker"
      ]
    }
  }
}
```

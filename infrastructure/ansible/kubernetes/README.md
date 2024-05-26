# Ansible

There are several way to install kubernetes, depending on the infrastructure to deploy on baremetal, cloud, vSphere, etc.. These options are mostly using the main stream distribution of Kubernetes, however versions like `k3s` are rarely supported.

The common tools and recommended for kubernetes community are:

- **kubeadm**: provides domain Knowledge of Kubernetes clusters' life cycle management, including self-hosted layouts, dynamic discovery services and so on. This is a manual way to deploy a Kubernetes cluster since you may create each node manually.
- **Kubespray**: Kubespray runs on bare metal and most clouds, using Ansible as its substrate for provisioning and orchestration. It is a good option to deploy Kubernetes cluster across multiple platforms. Kubespray has started using `kubeadm` internally for cluster creation since v2.3 in order to consume life cycle management domain knowledge from it and offload generic OS configuration things from it, which hopefully benefits both sides.
- **KOps**: performs the provisioning and orchestration itself, and as such is less flexible in deployment platforms. It is more tightly integrated with the unique features of the clouds it supports so it could be a better choice if you know that you will only be using one platform for the foreseeable future.
- **Ansible**: vanilla way to deploy a kubernetes cluster by provisioning using existing tools such as `kubeadm`, `k3s`, etc...
- **RKE**: is a Rancher distributed Kubernetes which deploys production-grade Kubernetes clusters on top of Docker containers. RKE is easy to manage Kubernetes distribution. Select this distribution if you want to use the Rancher Kubernetes Management platform.

In the case you may want to use **managed clusters** to deploy kubernetes you have the following options:

- **Cluster API**: Cluster API is a Kubernetes sub-project focused on providing declarative APIs and tooling to simplify provisioning, upgrading, and operating multiple Kubernetes clusters. It can be extended to support any infrastructure provider (AWS, Azure, vSphere, etc.) or bootstrap provider (kubeadm is default) you need.
- **Tools**: EKS (`eksctl create ..`), GKE (`gcloud container clusters create ...`), AKS (`az aks create ...`), etc.. provides a way to create kubernetes clusters automatically.
- **IaC**: Tools used for Infrastucture as Code (IAC) can also be used to deploy Kubernetes clusters like `CrossPlane`, `terraform` or `Pulumi`.

For further information about Installation method check this [link](https://kubedemy.io/kubernetes-installation-methods-the-complete-guide-update-2022).

In this document we will be using an Ansible collection to deploy Kubernetes using `K3s`, that ti's a light distribution of Kubernetes.

## System requirements

Easily bring up a cluster on machines running:

- [x] Debian
- [x] Ubuntu
- [x] Raspberry Pi OS
- [x] RHEL Family (CentOS, Redhat, Rocky Linux...)
- [x] SUSE Family (SLES, OpenSUSE Leap, Tumbleweed...)
- [x] ArchLinux

on processor architectures:

- [x] x64
- [x] arm64
- [x] armhf

The control node **must** have Ansible 8.0+ (ansible-core 2.15+)

All managed nodes in inventory must have:

- Passwordless SSH access
- Root access (or a user with equivalent permissions)

It is also recommended that all managed nodes disable firewalls and swap. See [K3s Requirements](https://docs.k3s.io/installation/requirements) for more information. Remote servers must have `Python3` already installed and SSH keys.

## Usage

Install Ansible

```bash
# Install Ansible using brew
brew install ansible
```

Install dependencies

```bash
# Install ansible dependencies for collections and roles
ansible-galaxy install -r requirements.yml --roles-path ~/.ansible/roles --force
ansible-galaxy collection install -r requirements.yml --collections-path ~/.ansible/collections --force
```

Second edit the inventory file to match your cluster setup. For example:

```yaml
k3s_cluster:
  children:
    server:
      hosts:
        sbc-server-1:
          ansible_host: 192.168.3.100
    agent:
      hosts:
        sbc-server-2:
          ansible_host: 192.168.3.101
        sbc-server-3:
          ansible_host: 192.168.3.102
```

If needed, you can also edit `vars` section at the bottom to match your environment.

If multiple hosts are in the server group the playbook will automatically setup k3s in HA mode with embedded etcd.
An odd number of server nodes is required (3,5,7). Read the [official documentation](https://docs.k3s.io/datastore/ha-embedded) for more information.

Setting up a loadbalancer or VIP beforehand to use as the API endpoint is possible but not covered here.

## Run Playbooks

```bash

# Check all servers in the inventory ('-i' flag is not necessary because it will use the default in ansible.cfg)
ansible all -m ping
ansible all -m ping -i inventory/inventory-staging.yml

# Create cluster with default inventory and token
ansible-playbook playbooks/site.yml

# If you need to deploy a specific inventory (staging)
ansible-playbook playbooks/site.yml -i inventory/inventory-staging.yml

# Create Cluster using external token
ansible-playbook playbooks/site.yml --extra-vars token=$MY_SECURE_TOKEN

# Reset Installation
ansible-playbook playbooks/reset.yml

ansible-playbook playbooks/reset.yml -i  inventory/inventory-staging.yml

# Reboot
ansible-playbook playbooks/reboot.yml

ansible-playbook playbooks/reboot.yml -i inventory-staging.yml

# Add logs (register: myvar)
- debug: var=myvar.stdout
```

## Connect to Cluster

After successful bootstrap, the `kubeconfig` of the cluster (`config.new`) is copied to the control node and merged with `~/.kube/config` under the `k3s-ansible` context. Assuming you have kubectl installed, you can confirm access to your Kubernetes cluster with the following:

```bash
# If no other cluster configured use following command to merge
# export KUBECONFIG=~/.kube/config.new
mv ~/.kube/config.new ~/.kube/config

# Switch to  k3s-ansible context
kubectl config use-context k3s-ansible

# Check all the nodes are running
kubectl get nodes -o wide

# Get all the pods currently running
kubectl get pods -A -o wide

# Install alias into ~/.zshrc or bash init file
alias ll="ls -al"
alias k="kubectl"

```

## Airgap Install

Airgap installation is supported via the `airgap_dir` variable. This variable should be set to the path of a directory containing the K3s binary and images. The release artifacts can be downloaded from the [K3s Releases](https://github.com/k3s-io/k3s/releases). You must download the appropriate images for you architecture (any of the compression formats will work).

An example folder for an x86_64 cluster:

```bash
$ ls ./playbooks/my-airgap/
total 248M
-rwxr-xr-x 1 $USER $USER  58M Nov 14 11:28 k3s
-rw-r--r-- 1 $USER $USER 190M Nov 14 11:30 k3s-airgap-images-amd64.tar.gz

$ cat inventory.yml
...
airgap_dir: ./my-airgap # Paths are relative to the playbook directory
```

Additionally, if deploying on a OS with SELinux, you will also need to download the latest [k3s-selinux RPM](https://github.com/k3s-io/k3s-selinux/releases/latest) and place it in the airgap folder.

It is assumed that the control node has access to the internet. The playbook will automatically download the k3s install script on the control node, and then distribute all three artifacts to the managed nodes.

## Local Testing

A Vagrantfile is provided that provision a 5 nodes cluster using Vagrant (LibVirt or Virtualbox as provider). To use it:

```bash
vagrant up
```

By default, each node is given 2 cores and 2GB of RAM and runs Ubuntu 20.04. You can customize these settings by editing the `Vagrantfile`.

## Todo

Following are the changes pending to be made:

- Use `Kube-Vip` to deploy external Load Balancer for the HA Cluster
- Inject External secrets such as Github token, etc..
- Install ArgoCD to bootstrap applications

## Need More Features?

This project is intended to provide a "vanilla" K3s install. If you need more features, such as:

- Private Registry
- Advanced Storage (Longhorn, Ceph, etc)
- External Database
- External Load Balancer or VIP
- Alternative CNIs

See these other projects:

- [https://github.com/PyratLabs/ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s)
- [https://github.com/techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible)
- [https://github.com/jon-stumpf/k3s-ansible](https://github.com/jon-stumpf/k3s-ansible)
- [https://github.com/alexellis/k3sup](https://github.com/alexellis/k3sup)

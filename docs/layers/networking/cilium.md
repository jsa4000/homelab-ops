# Cilium

![Cilium Logo](https://cdn.jsdelivr.net/gh/cilium/cilium@main/Documentation/images/logo-dark.png)

Cilium is a networking, observability, and security solution with an eBPF-based dataplane. It provides a simple flat Layer 3 network (OSI Model) with the ability to span multiple clusters in either a native routing or overlay mode. It is L7-protocol aware and can enforce network policies on L3-L7 using an identity based security model that is decoupled from network addressing.

Cilium implements distributed load balancing for traffic between pods and to external services, and is able to fully replace `kube-proxy`, using efficient hash tables in eBPF allowing for almost unlimited scale. It also supports advanced functionality like integrated ingress and egress gateway, bandwidth management and service mesh, and provides deep network and security visibility and monitoring.

A new Linux kernel technology called `eBPF` is at the foundation of Cilium. It supports dynamic insertion of eBPF bytecode into the Linux kernel at various integration points such as: network IO, application sockets, and tracepoints to implement security, networking and visibility logic. eBPF is highly efficient and flexible. To learn more about eBPF, visit `eBPF.io`.

![Overview of Cilium features for networking, observability, service mesh, and runtime security](../../images/cilium-overview.png)

## eBPF

### Obserbability

### Security

* Network Traffic
* File Activity
* Running Executables
* Changing Priviledges

## Features

### Kube Proxy Replacement

The kube-proxy replacement offered by Cilium's CNI is a very powerful feature which can increase performance for large Kubernetes clusters. This feature uses an eBPF data plane to replace the kube-proxy implementations offered by Kubernetes distributions typically implemented with either iptables or ipvs. When using other networking infrastructure, the otherwise hidden Cilium eBPF implementation used to replace kube-proxy can bleed through and provide unintended behaviors. We see this when trying to use Istio service mesh with Cilium's kube-proxy replacement: kube-proxy replacement, by default, **breaks** Istio.

### LoadBalancer IP Address Management (LB-IPAM)

Cilium 1.13 introduced LB-IPAM support and 1.14 added L2 announcement capabilities. Cilium also has support for Border Gateway Protocol (BGP) for routing capabilities.

!!! note

Cilium doesn't use `metallb` anymore, it uses its own bgp speaker made with gobgp. They used it initially until they reached feature parity with gobgp.

### BGP (Border Gateway Protocol)

BRP is a routing protocol.

DNS (domain name system) servers provide the IP address, but BGP provides the most efficient way to reach that IP address. Roughly speaking, if DNS is the Internet's address book, then BGP is the Internet's road map (Tomtom).

## Installation

### CLI

Cilium cli can be installed in different ways using following [link](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/).

```bash
# Use homebrew to
brew install cilium-cli

# Test the version
cilium version
```

### Operator

There are several ways to install Cilium operator.

```bash
# Using the cilium cli, this will use helm behind the scenes.
cilium install --version 1.15.3

```

!!! note

Depending on the kubernetes distribution GKE,AKS,EKS,Openshift cilium must need to be installed using specific configuration

```bash
#
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
```

To validate that Cilium has been properly installed run following command.

```bash
# Check cilium status by using the following command
cilium status -n networking --wait

# Check cilium status by using the following command
cilium config -n networking view
```

Run the following command to validate that your cluster has proper network connectivity.

```bash
# Check the connectivity test
cilium connectivity -n networking test
```

## References

* [Kubernetes LoadBalance service using Cilium BGP control plane](https://medium.com/@valentin.hristev/kubernetes-loadbalance-service-using-cilium-bgp-control-plane-8a5ad416546a)
* [Migrating from MetaLB to Cilium](https://blog.stonegarden.dev/articles/2023/12/migrating-from-metallb-to-cilium/)

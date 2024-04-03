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

### CNI

There are several ways to install Cilium operator. The recommended way to install cilium is using a distribution with no CNI pre-installed. There are ways to prevent CNI to be installed in some distributions.

!!! note

    Depending on the kubernetes distribution GKE, AKS, EKS, Openshift, K3s, etc.. cilium must need to be installed using specific configuration.

    ```bash
    # For K3s cluster it's necessary to disable current CNI (flannel) and Network Policies.
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -
    ```

```bash
# Using the cilium cli, this will use helm behind the scenes.
cilium install --version 1.15.3

# Or Using directly helm
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.3 \
   --namespace kube-system \
   --set operator.replicas=1
```

!!! note Restart unmanaged Pods

    If you did not create a cluster with the nodes tainted with the taint `node.cilium.io/agent-not-ready`, then unmanaged pods **need** to be restarted manually. Restart all already running pods which are not running in host-networking mode to ensure that Cilium starts managing them. This is required to ensure that all pods which have been running before Cilium was deployed have network connectivity provided by Cilium and NetworkPolicy applies to them.

    ```bash
    kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
    ```

Validate Cilium has been properly installed into kubernetes cluster running following command.

```bash
# Check cilium status by using the following command
cilium status --wait -n networking

# Check cilium configuration options
cilium config view -n networking

# Filter configuration by keyword
cilium config view -n networking  | grep l2
```

Run the following command to validate that your cluster has proper network connectivity.

```bash
# Check the connectivity test
cilium connectivity test -n networking
```

### Hubble

Observability is provided by **Hubble** which enables deep visibility into the communication and behavior of services as well as the networking infrastructure in a completely transparent manner.

By default, **Hubble API** operates within the scope of the individual node on which the Cilium agent runs. This confines the network insights to the traffic observed by the local Cilium agent. Hubble CLI (`hubble`) can be used to query the Hubble API provided via a local Unix Domain Socket. The Hubble CLI binary is installed by default on Cilium agent pods.

Upon deploying **Hubble Relay**, network visibility is provided for the entire cluster or even multiple clusters in a ClusterMesh scenario. In this mode, Hubble data can be accessed by directing Hubble CLI (`hubble`) to the Hubble Relay service or via Hubble UI. Hubble UI is a web interface which enables automatic discovery of the services dependency graph at the L3/L4 and even L7 layer, allowing user-friendly visualization and filtering of data flows as a service map.

First you will need to install `hubble relay` and `hubble ui` into Kubernetes.

```bash
# Cilium must be isntalled previously

# Using cilium cli
cilium hubble enable

# Using helm
helm upgrade cilium cilium/cilium --version 1.15.3 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

## References

* [Kubernetes LoadBalance service using Cilium BGP control plane](https://medium.com/@valentin.hristev/kubernetes-loadbalance-service-using-cilium-bgp-control-plane-8a5ad416546a)
* [Migrating from MetaLB to Cilium](https://blog.stonegarden.dev/articles/2023/12/migrating-from-metallb-to-cilium/)

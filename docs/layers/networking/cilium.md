# Cilium

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

## References

* [Kubernetes LoadBalance service using Cilium BGP control plane](https://medium.com/@valentin.hristev/kubernetes-loadbalance-service-using-cilium-bgp-control-plane-8a5ad416546a)
* [Migrating from MetaLB to Cilium](https://blog.stonegarden.dev/articles/2023/12/migrating-from-metallb-to-cilium/)

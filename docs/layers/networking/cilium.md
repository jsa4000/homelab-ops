# Cilium

![Cilium Logo](https://cdn.jsdelivr.net/gh/cilium/cilium@main/Documentation/images/logo-dark.png)

Cilium is a networking, observability, and security solution with an eBPF-based dataplane. It provides a simple flat Layer 3 network (OSI Model) with the ability to span multiple clusters in either a native routing or overlay mode. It is L7-protocol aware and can enforce network policies on L3-L7 using an identity based security model that is decoupled from network addressing.

Cilium implements distributed load balancing for traffic between pods and to external services, and is able to fully replace `kube-proxy`, using efficient hash tables in eBPF allowing for almost unlimited scale. It also supports advanced functionality like integrated ingress and egress gateway, bandwidth management and service mesh, and provides deep network and security visibility and monitoring.

A new Linux kernel technology called `eBPF` is at the foundation of Cilium. It supports dynamic insertion of eBPF bytecode into the Linux kernel at various integration points such as: network IO, application sockets, and tracepoints to implement security, networking and visibility logic. eBPF is highly efficient and flexible. To learn more about eBPF, visit `eBPF.io`.

![Overview of Cilium features for networking, observability, service mesh, and runtime security](../../images/cilium-overview.png)

This is an overview of the main functionalities of Cilium:

* Protect and secure APIs transparently
* Secure service to service communication based on identities
* Secure access to and from external services
* Simple Networking
* Load Balancing
* Bandwidth Management
* Monitoring and Troubleshooting

## Components

A deployment of Cilium and Hubble consists of the following components running in a cluster:

![Hubble](../../images/cilium-components.webp)

### Cilium

#### The Cilium agent

The **Cilium agent** (`cilium-agent`) runs on each node in the cluster. At a high-level, the agent accepts configuration via Kubernetes or APIs that describes networking, service load-balancing, network policies, and visibility & monitoring requirements.

The Cilium agent listens for events from orchestration systems such as Kubernetes to learn when containers or workloads are started and stopped. It manages the eBPF programs which the Linux kernel uses to control all network access in / out of those containers.

#### The Cilium CLI client

The **Cilium CLI client** (`cilium`) is a command-line tool that is installed along with the Cilium agent. It interacts with the REST API of the Cilium agent running on the same node. The CLI allows inspecting the state and status of the local agent. It also provides tooling to directly access the eBPF maps to validate their state.

!!! note

    The in-agent Cilium CLI client described here **should not** be confused with the [command line tool](https://github.com/cilium/cilium-cli) for quick-installing, managing and troubleshooting Cilium on Kubernetes clusters, which also has the name cilium. That tool is typically installed remote from the cluster, and uses `kubeconfig` information to access Cilium running on the cluster via the Kubernetes API.

#### The Cilium operator

The **Cilium Operator** is responsible for managing duties in the cluster which should logically be handled once for the entire cluster, rather than once for each node in the cluster. The Cilium operator is not in the critical path for any forwarding or network policy decision. A cluster will generally continue to function if the operator is temporarily unavailable. However, depending on the configuration, failure in availability of the operator can lead to:

* Delays in IP Address Management (IPAM) and thus delay in scheduling of new workloads if the operator is required to allocate new IP addresses
* Failure to update the kvstore heartbeat key which will lead agents to declare kvstore unhealthiness and restart.

#### The CNI plugin

The **CNI plugin** (`cilium-cni`) is invoked by Kubernetes when a pod is scheduled or terminated on a node. It interacts with the Cilium API of the node to trigger the necessary datapath configuration to provide networking, load-balancing and network policies for the pod.

### Hubble

#### Hubble Server

The **Hubble server** runs on each node and retrieves the eBPF-based visibility from Cilium. It is embedded into the **Cilium agent** in order to achieve high performance and low-overhead. It offers a gRPC service to retrieve flows and Prometheus metrics.

#### Hubble Relay

**Hubble Relay** (`hubble-relay`) is a standalone component which is aware of all running Hubble servers and offers cluster-wide visibility by connecting to their respective gRPC APIs and providing an API that represents all servers in the cluster.

#### The Hubble CLI

The **Hubble CLI** (`hubble`) is a command-line tool able to connect to either the gRPC API of `hubble-relay` or the local server to retrieve flow events.

#### The Hubble UI

The **Hubble UI** (`hubble-ui`) utilizes relay-based visibility to provide a graphical service dependency and connectivity map.

### eBPF

eBPF is a Linux kernel bytecode interpreter originally introduced to filter network packets, e.g. tcpdump and socket filters. It has since been extended with additional data structures such as hashtable and arrays as well as additional actions to support packet mangling, forwarding, encapsulation, etc. An in-kernel verifier ensures that eBPF programs are safe to run and a JIT compiler converts the bytecode to CPU architecture specific instructions for native execution efficiency. eBPF programs can be run at various hooking points in the kernel such as for incoming and outgoing packets.

Cilium is capable of probing the Linux kernel for available features and will automatically make use of more recent features as they are detected.

### Data Store

Cilium requires a data store to propagate state between agents. It supports the following data stores:

#### Kubernetes CRDs (Default)

The default choice to store any data and propagate state is to use Kubernetes custom resource definitions (CRDs). CRDs are offered by Kubernetes for cluster components to represent configurations and state via Kubernetes resources.

#### Key-Value Store

All requirements for state storage and propagation can be met with Kubernetes CRDs as configured in the default configuration of Cilium. A key-value store can optionally be used as an optimization to improve the scalability of a cluster as change notifications and storage requirements are more efficient with direct key-value store usage.

The currently supported key-value stores are base on `etcd`.

## Feature

### Security

* Network Traffic
* File Activity
* Running Executables
* Changing Priviledges

## Features

### Routing

[Routing](https://docs.cilium.io/en/stable/network/concepts/routing/)

### Kube Proxy Replacement

The kube-proxy replacement offered by Cilium's CNI is a very powerful feature which can increase performance for large Kubernetes clusters. This feature uses an eBPF data plane to replace the kube-proxy implementations offered by Kubernetes distributions typically implemented with either iptables or ipvs. When using other networking infrastructure, the otherwise hidden Cilium eBPF implementation used to replace kube-proxy can bleed through and provide unintended behaviors. We see this when trying to use Istio service mesh with Cilium's kube-proxy replacement: kube-proxy replacement, by default, **breaks** Istio.

### LoadBalancer IP Address Management (LB-IPAM)

In Cilium 1.13, it was added support for **LoadBalancer IP Address Management** (LB-IPAM) and the ability to *allocate* IP addresses to Kubernetes Services of the type `LoadBalancer`.

![IP Address Management (LB-IPAM)](../../images/ipam-diagram.webp)

For users who do not want to use **BGP** or that just want to make these IP addresses accessible over the **local network**, in Cilium 1.14 a new feature called **L2 Announcements** was added. When you deploy a *L2 Announcement Policy*, Cilium will start responding to `ARP` requests from local clients for ExternalIPs and/or LoadBalancer IPs.

![L2 Announcements](../../images/l2-announcement.png)

!!! note

    Typically, this would have required a tool like `MetalLB` but Cilium now natively supports this functionality. Cilium doesn't use `MetalLB` anymore, now it uses its own `BGP` speaker made with `gobgp`. They used it initially until they reached feature parity with gobgp.

`LB-IPAM` works seamlessly with Cilium `BGP`. The IP addresses allocated by Cilium can be advertised to `BGP` peers to integrate your cluster with the rest of your network.

Cloud providers natively provide this feature for managed Kubernetes Services and therefore this feature is more one for self-managed Kubernetes deployments or home labs.

### BGP (Border Gateway Protocol)

BGP is a routing protocol.

DNS (domain name system) servers provide the IP address, but BGP provides the most efficient way to reach that IP address. Roughly speaking, if DNS is the Internet's address book, then BGP is the Internet's road map (Tomtom).

### Threat Model

[Threat Model](https://docs.cilium.io/en/latest/security/threat-model/)

### Observability

**Hubble** is a fully distributed networking and security observability platform. It is built on top of Cilium and eBPF to enable deep visibility into the communication and behavior of services as well as the networking infrastructure in a completely transparent manner.

By building on top of Cilium, Hubble can leverage eBPF for visibility. By relying on eBPF, all visibility is programmable and allows for a dynamic approach that minimizes overhead while providing deep and detailed visibility as required by users. Hubble has been created and specifically designed to make best use of these new eBPF powers.

![Hubble](../../images/cilium-hubble.webp)

Hubble can answer questions such as:

#### Service dependencies & communication map

* What services are communicating with each other? How frequently? What does the service dependency graph look like?
* What HTTP calls are being made? What Kafka topics does a service consume from or produce to?

#### Network monitoring & alerting

* Is any network communication failing? Why is communication failing? Is it DNS? Is it an application or network problem? Is the communication broken on layer 4 (TCP) or layer 7 (HTTP)?
* Which services have experienced a DNS resolution problem in the last 5 minutes? Which services have experienced an interrupted TCP connection recently or have seen connections timing out? What is the rate of unanswered TCP SYN requests?

#### Application monitoring

* What is the rate of 5xx or 4xx HTTP response codes for a particular service or across all clusters?
* What is the 95th and 99th percentile latency between HTTP requests and responses in my cluster? Which services are performing the worst? What is the latency between two services?

#### Security observability

* Which services had connections blocked due to network policy? What services have been accessed from outside the cluster? Which services have resolved a particular DNS name?

## Installation

These are the generic instructions on how to install Cilium into any Kubernetes cluster. The installer will attempt to automatically pick the best configuration options for you. Please see the other installation options for distribution/platform specific instructions which also list the ideal default configuration for particular platforms.

### CLI

The Cilium CLI can be used to install Cilium, inspect the state of a Cilium installation, and enable/disable various features (e.g. clustermesh, Hubble).

Cilium cli can be installed in different ways using following [instructions](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/).

```bash
# Use homebrew to
brew install cilium-cli

# Test the version
cilium version
```

### CNI

There are several ways to install Cilium. The recommended way to install cilium is using a distribution with no CNI pre-installed. There are several ways to prevent CNI to be installed in some distributions.

!!! note

    Depending on the kubernetes distribution GKE, AKS, EKS, Openshift, K3s, etc.. cilium need to be installed using custom configuration.

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

!!! Restart Unmanaged Pods

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

!!! note

    Cilium installed allows to configure hubble service with TLS, metrics, port and other features.

```bash
# Cilium must be isntalled previously

# Using cilium cli (without ui)
cilium hubble enable

# Enable cilium with ui (hubble must be disabled)
cilium hubble enable --ui

# Using helm enabling global features.
helm upgrade cilium cilium/cilium --version 1.15.3 \
   --namespace kube-system \
   --reuse-values \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true
```

Install `hubble` cli to interact with Hubble API for observability and troubleshooting.

```bash
# Install hubble using homebrew
brew install hubble
```

Validate the hubble installation

```bash
# Expose the Hubble API by using Port forward on port :4245
cilium hubble port-forward -n networking

# In other terminal use following command to test the hubble status
hubble status

# You can also query the flow API and look for flows
hubble observe
```

Open the Hubble UI using cilium cli

```bash
# Use following command for port forwarding (port 12000)
cilium hubble ui -n networking

# Run the cilium test to get some traffic (different terminal)
while true; do cilium connectivity test -n networking; done

# http://localhost:12000/
```

## Demo

In our Star Wars-inspired example, there are three microservices applications: `deathstar`, `tiefighter`, and `xwing`.

* The `deathstar` runs an HTTP webservice on port 80, which is exposed as a Kubernetes Service to load-balance requests to deathstar across two pod replicas. The deathstar service provides landing services to the empire's spaceships so that they can request a landing port.
* The `tiefighter` pod represents a landing-request client service on a typical empire ship.
* The `xwing` represents a similar service on an alliance ship.

![Star Wars-inspired demo](../../images/cilium_http_gsg.webp)

They exist so that we can test different security policies for access control to deathstar landing services.

### Deployment

The file `http-sw-app.yaml` contains a Kubernetes Deployment for each of the three services. Each deployment is identified using the Kubernetes labels (`org=empire, class=deathstar`), (`org=empire, class=tiefighter`), and (`org=alliance, class=xwing`). It also includes a `deathstar-service`, which load-balances traffic to all pods with label (`org=empire, class=deathstar`).

```bash
# Deploy the base demo resources into default namespace
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.15.3/examples/minikube/http-sw-app.yaml

# Check the statuses
kubectl get pods,svc
```

Each `pod` will be represented in Cilium as an `Endpoint` in the local cilium agent. We can invoke the cilium tool inside the Cilium pod to list them (in a single-node installation `kubectl -n networking exec ds/cilium -- cilium-dbg endpoint list` lists them all, but in a multi-node installation, only the ones running on the same node will be listed)

Get the ingress and egress enforcements and policies currently applied to these pods/endpoints.

```bash
# List all endpoints (pods) available in the current node (each agent manage it's own pods)
kubectl -n networking exec ds/cilium -- cilium-dbg endpoint list

# Get endpoints from the CRD
kubectl get cep
kubectl get cep -o wide
```

### Check Current Access

From the perspective of the `deathstar` service, only the ships with label `org=empire` are allowed to connect and request landing. Since we have no rules enforced, both `xwing` and `tiefighter` will be able to request landing. To test this, use the commands below.

```bash
# Check connectivity between xwing and deathstar
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# Check connectivity between tiefighter and deathstar
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```

### Apply an L3/L4 Policy

When using Cilium, endpoint IP addresses are irrelevant when defining security policies. Instead, you can use the labels assigned to the pods to define security policies. The policies will be applied to the right pods based on the labels irrespective of where or when it is running within the cluster.

We'll start with the basic policy restricting deathstar landing requests to only the ships that have label (`org=empire`). This will not allow any ships that don't have the `org=empire` label to even connect with the deathstar service. This is a simple policy that filters only on IP protocol (network layer 3) and TCP protocol (network layer 4), so it is often referred to as an L3/L4 network security policy.

![Star Wars-inspired demo](../../images/cilium_http_l3_l4_gsg.webp)

```yaml title="sw_l3_l4_policy.yaml""
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "rule1"
spec:
  description: "L3-L4 policy to restrict deathstar access to empire ships only"
  endpointSelector:
    matchLabels:
      org: empire
      class: deathstar
  ingress:
  - fromEndpoints:
    - matchLabels:
        org: empire
    toPorts:
    - ports:
      - port: "80"
        protocol: TCP
```

```bash
# Create CiliumNetworkPolicy resource
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.15.3/examples/minikube/sw_l3_l4_policy.yaml
```

Now if we run the landing requests again, only the tiefighter pods with the label `org=empire` will succeed. The xwing pods will be blocked!

```bash
# tiefighter pods with the label org=empire will succeed
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

# xwing pods with the label org!=empire will not succeed
kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
```

### Inspecting the Policy

If we run cilium-dbg endpoint list again we will see that the pods with the label `org=empire` and `class=deathstar` now have ingress policy enforcement `enabled` as per the policy above.

```bash
# Check policy enabled on deathstar endpoint
kubectl -n networking exec ds/cilium -- cilium-dbg endpoint list

kubectl get cnp
kubectl describe cnp rule1
```

## Labs

* [IPAM and L2 Service Announcement Lab](https://isovalent.com/labs/cilium-lb-ipam-l2-announcements/)

## References

* [Kubernetes LoadBalance service using Cilium BGP control plane](https://medium.com/@valentin.hristev/kubernetes-loadbalance-service-using-cilium-bgp-control-plane-8a5ad416546a)
* [Migrating from MetaLB to Cilium](https://blog.stonegarden.dev/articles/2023/12/migrating-from-metallb-to-cilium/)

# Metallb

## Address Assignment

**Metallb** is not a load balancer but it has functionality for IP Address Management to the cluster, in order to be able to reach to nodes and services by using a single IP Address.

### L2 Advertisement

For this address assignment mode the client and the cluster must ber in the same local network.

### BGP Advertisement

This mode is more advanced and provides a real load balancing capabilities. It requires interacting with a BGP enabled router.

## References

* [MetalLB, Kubernetes Bare Metal Load Balancing Youtube](https://www.youtube.com/watch?v=4_3B0lAsXWQ)

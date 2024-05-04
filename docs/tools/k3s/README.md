# K3s

## Install

### Containerd

```bash
# Systems
SYSTEM_OS=linux
SYSTEM_ARCH=arm64

# Versions
CONTAINERD_VERSION=1.7.15
RUNC_VERSION=1.1.12
CNI_VERSION=1.4.1

# Download containerd
wget https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-$SYSTEM_OS-$SYSTEM_ARCH.tar.gz

# Unpack
sudo tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-$SYSTEM_OS-$SYSTEM_ARCH.tar.gz

#Install runc
wget https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.$SYSTEM_ARCH
sudo install -m 755 runc.$SYSTEM_ARCH /usr/local/sbin/runc

# Download and install CNI plugins :
wget https://github.com/containernetworking/plugins/releases/download/v$CNI_VERSION/cni-plugins-linux-$SYSTEM_ARCH-v$CNI_VERSION.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-$SYSTEM_OS-$SYSTEM_ARCH-v$CNI_VERSION.tgz
sudo chown -R root:root /opt/cni/bin

# Configure containerd
sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
# NOTE: kubelet and containerd config need to agree about what cgroup driver to use, so do not modify containerd config
# In k3s it would be needed to set '--kubelet-arg cgroup-driver=systemd'
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
# Pperform syncfs after pull https://github.com/containerd/containerd/pull/9401
sudo sed -i 's/image_pull_with_sync_fs \= false/image_pull_with_sync_fs \= true/g' /etc/containerd/config.toml
sudo curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service

# Step 5: Start containerd service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

Verify `containerd` is running

```bash
# Verify containerd is running
sudo systemctl status containerd
```

Remove containerd

```bash
# Stop containerd
sudo systemctl disable --now containerd

# Remove containerd
sudo rm -r /etc/containerd
sudo rm -r /run/containerd
sudo rm -r /var/lib/containerd/
sudo rm /etc/systemd/system/containerd.service
```

### k3s

Create a `k3s` with not HA (*High Availability*) on master nodes and not distributed `etcd`.

```bash
# Create Master Note (192.168.205.101)
# Use K3S_KUBECONFIG_MODE="644" for develop, so sudo is not needed
INSTALL_K3S_VERSION=v1.29.3+k3s1
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$INSTALL_K3S_VERSION K3S_KUBECONFIG_MODE="644" sh -

# Get the token from master
echo "K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)"

# Join Workers
# Copy the previous K3S_TOKEN into workers.
K3S_TOKEN=<token>
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.205.101:6443 K3S_TOKEN=$K3S_TOKEN sh -

# Test example deployment
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/docs/examples/chashsubset/deployment.yaml
kubectl get pods -w -o wide

# Uninstalling Servers
/usr/local/bin/k3s-uninstall.sh

# Uninstalling Agents
/usr/local/bin/k3s-agent-uninstall.sh

```

Create `k3s` cluster with already existing `containerd` using `--container-runtime-endpoint` flag.

> containerd default socket is `unix:///run/containerd/containerd.sock`

```bash
# Create Master Note (192.168.205.101)
# Use K3S_KUBECONFIG_MODE="644" for develop, so sudo is not needed
INSTALL_K3S_VERSION=v1.29.3+k3s1
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=$INSTALL_K3S_VERSION K3S_KUBECONFIG_MODE="644" sh -s - --container-runtime-endpoint="unix:///run/containerd/containerd.sock"

# Get the token from master
echo "K3S_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)"

# Join Workers
# Copy the previous K3S_TOKEN into workers.
K3S_TOKEN=<token>
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.205.101:6443 K3S_TOKEN=$K3S_TOKEN sh -s - --container-runtime-endpoint="unix:///run/containerd/containerd.sock"

# install CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Test example deployment
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/docs/examples/chashsubset/deployment.yaml
kubectl get pods -o wide -w

# Uninstalling Servers
/usr/local/bin/k3s-uninstall.sh

# Uninstalling Agents
/usr/local/bin/k3s-agent-uninstall.sh

```

## FAQ

### Error `exec format error`

This container error is mostly due the following scenarios:

* The image currently running is not supported by the OS. For example running `amd64` image into `arm64` platform will throw this exception.
* By missing the `command` or `entrypoint` of the OCI image, so when the container start it can reach to this error.
* Lastly, *and the actual error*, is when the layers are pulled by the container runtime, but for some reason (restart, networking issue, I/O Throttling, etc..) those become corrupted so any time the container starts it throws an error.

In `containerd` configuration file `/etc/containerd/config.toml`, set `image_pull_with_sync_fs = true` to check and sync the image layers from the `snapshotter`, usually the recommended `overlayfs`.

* [exec user process caused: exec format error](https://github.com/containerd/containerd/issues/5854)
* [Add option to perform syncfs after pull](https://github.com/containerd/containerd/pull/9401)

```bash
[plugins."io.containerd.grpc.v1.cri"]

    image_pull_with_sync_fs = true
```

### Error Kernel modules

`error="program cil_from_overlay: replacing clsact qdisc for interface cilium_vxlan: no such file or directory"`

In order for the BPF feature to be enabled properly, the [following kernel](https://docs.cilium.io/en/v1.7/install/system_requirements/#linux-kernel) configuration options must be enabled. This is typically the case with distribution kernels. When an option can be built as a module or statically linked, either choice is valid.

```bash
# Get Kernel installed
sudo cat /boot/config-6.1.43-rockchip-rk3588 | grep -E "CONFIG_BPF|CONFIG_BPF_SYSCALL|CONFIG_NET_CLS_BPF|CONFIG_BPF_JIT|CONFIG_NET_CLS_ACT|CONFIG_NET_SCH_INGRESS|CONFIG_CRYPTO_SHA1|CONFIG_CRYPTO_USER_API_HASH"

# Add single modules to kernel
sudo modprobe xfrm_user

# Add multiple modules to kernel
sudo modprobe -a ipt_REJECT xt_mark xt_multiport xt_TPROXY xt_CT sch_ingress ip_set cls_bpf xfrm_user configs

# Check Kernel modules
cat /proc/modules | grep ipt_REJECT
```

### Kubernetes Node Not Ready

* [Kubernetes Node Not Ready Error and How to Fix It](https://lumigo.io/kubernetes-troubleshooting/kubernetes-node-not-ready-error-and-how-to-fix-it/)
* [Diagnosis and Troubleshooting of a Kubernetes Node in "Not Ready" State](https://medium.com/@diego_maia/diagnosis-and-troubleshooting-of-a-kubernetes-node-in-not-ready-state-f5d0d5e5b061)
* [Worker latency profiles](https://docs.openshift.com/container-platform/4.12/nodes/clusters/nodes-cluster-worker-latency-profiles.html)
* [How To Make Kubernetes React Faster When Nodes Fail?](https://medium.com/tailwinds-navigator/kubernetes-tip-how-to-make-kubernetes-react-faster-when-nodes-fail-1e248e184890)

This is what happens when node dies or go into offline mode:

* The `kubelet` posts its status to masters by `--node-status-update-fequency=10s`.
* `kube-controller-manager` is monitoring all the nodes by `--node-monitor-period=5s`
* `kube-controller-manager` will see the node is unresponsive and has the grace period `--node-monitor-grace-period=40s` until it considers node **unhealthy**. > This parameter should be in N x `node-status-update-fequency`
* Once the node marked unhealthy, the `kube-controller-manager` will remove the pods based on `--pod-eviction-timeout=5m`

#### Medium worker latency profile

* Use the MediumUpdateAverageReaction profile if the network latency is slightly higher than usual.
* The MediumUpdateAverageReaction profile reduces the frequency of kubelet updates to 20 seconds and changes the period that the Kubernetes Controller Manager waits for those updates to 2 minutes. The pod eviction period for a pod on that node is reduced to 60 seconds. If the pod has the tolerationSeconds parameter, the eviction waits for the period specified by that parameter.
* The Kubernetes Controller Manager waits for 2 minutes to consider a node unhealthy. In another minute, the eviction process starts.

|Component|Parameter|Value|
|---|---|----|
|kubelet|`node-status-update-frequency`|`1m`|
|Kubelet Controller Manager|`node-monitor-grace-period`|`5m`|
|Kubernetes API Server Operator|`default-not-ready-toleration-seconds`|`60s`|
|Kubernetes API Server Operator|`default-unreachable-toleration-seconds`|`60s`|

### Low worker latency profile**

* Use the LowUpdateSlowReaction profile if the network latency is extremely high.
* The LowUpdateSlowReaction profile reduces the frequency of kubelet updates to 1 minute and changes the period that the Kubernetes Controller Manager waits for those updates to 5 minutes. The pod eviction period for a pod on that node is reduced to 60 seconds. If the pod has the tolerationSeconds parameter, the eviction waits for the period specified by that parameter.
* The Kubernetes Controller Manager waits for 5 minutes to consider a node unhealthy. In another minute, the eviction process starts.

|Component|Parameter|Value|
|---|---|----|
|kubelet|`node-status-update-frequency`|`20s`|
|Kubelet Controller Manager|`node-monitor-grace-period`|`2m`|
|Kubernetes API Server Operator|`default-not-ready-toleration-seconds`|`60s`|
|Kubernetes API Server Operator|`default-unreachable-toleration-seconds`|`60s`|

#### Troubleshooting

For troubleshooting use following command:

```bash
# Watch the pods and nodes statuses
watch -n 0.5 kubectl get pods -A -o wide
watch -n 0.5 kubectl get pods -A -o wide

# Check that you have resolved any Additional OS Preparation
k3s check-config

# Check the events throw to kubernetes to get the state
kubectl get events -A

# Get the status
sudo systemctl status k3s

# Get the logs
sudo journalctl -u k3s | grep kubelet
```

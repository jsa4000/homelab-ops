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
sudo systemctl status containerd
```

Remove containerd

```bash
# Stop containerd
sudo systemctl disable --now containerd

# Remove containerd
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
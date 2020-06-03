#!/bin/bash

$CRI_VERSION = 1.3.4

# Perform initial updates and install pre-requisites
# do-release-upgrade
sudo apt-get update && sudo apt-get install -y apt-transport-https curl zip gnupg-agent software-properties-common

# Disable swap and remove swap file as the kubelet will fail if swap
# is on
sudo rm -f /etc/fstab
sudo swapoff -a

# Allow iptables see bridged network
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables   = 1
net.bridge.bridge-nf-call-iptables    = 1
net.ipv4.ip_forward                   = 1
EOF
sudo sysctl --system

# TODO: Write command to check kubernetes required ports

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Install container runtime and configure
wget https://github.com/containerd/containerd/releases/download/v$CRI_VERSION/containerd-${CRI_VERSION}.linux-amd64.tar.gz
mkdir containerd
tar -xvf containerd-$CRI_VERSION.linux-amd64.tar.gz -C containerd
sudo mv containerd/bin/* /bin

sudo mkdir -p /etc/containerd

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter 
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd

# Install and configure kubeadm, kubelet and kubectl on nodes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
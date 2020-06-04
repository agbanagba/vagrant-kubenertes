#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset


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

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

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

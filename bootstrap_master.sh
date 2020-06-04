#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# pull control plane initialization images and create cluster
sudo kubeadm config images pull
NODENAME=$(hostname -s)
sudo kubeadm init --apiserver-advertise-address=192.168.10.10 --apiserver-cert-extra-sans=192.168.10.10 \
    --node-name master --pod-network-cidr=192.168.0.0/16 --cri-socket=/run/containerd/containerd.sock

# Copy kubeconfig on control plane
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm token create --print-join-command > ./join-node.sh
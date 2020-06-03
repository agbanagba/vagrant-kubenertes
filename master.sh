#!/bin/bash

# pull control plane initialization images and create cluster
sudo kubeadm config images pull
sudo kubeadm init --apiserver-advertise-address=$ --apiserver-cert-extra-sans=$ --name master --pod-network-cidr=$

# Copy kubeconfig on control plane
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm token create --print-join-command > ./join-node.sh
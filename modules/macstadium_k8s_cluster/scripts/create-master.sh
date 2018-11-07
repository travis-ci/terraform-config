#!/bin/bash

# Install jq to be able to get the join token back to Terraform later
apt-get install -y jq

# This CIDR is required by the Flannel network provider
kubeadm init --pod-network-cidr=10.244.0.0/16

# This allows us to use kubectl as root on the master VM
export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p /root/.kube
cp $KUBECONFIG /root/.kube/config

# Install the flannel network provider
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

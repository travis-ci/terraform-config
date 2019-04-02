#!/bin/bash

if command -v kubeadm >/dev/null 2>&1; then
  echo "Kubernetes is already installed. Skipping."
  exit 0
fi

# Swap must be disable to use kubeadm
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main"

apt-get update
apt-get install -y kubeadm kubelet kubectl

#!/bin/bash

###Add these IP tables Rule:
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

lsmod | grep br_netfilter
lsmod | grep overlay

###Sysctl params required by setup, params persist after reboots:
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

###Apply sysctl params without reboot:
sudo sysctl --system

### Docker Install using the rpm repository:
echo "Docker Install..."

sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

echo "Docker Installed...sucessfully"

### Containerd Configuring:
echo "Containerd Configuring..."

sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml


sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd


### Installing Kubernetes and overwrites existing config in "/etc/yum.repos.d/kubernetes.repo":
echo "K8s Install..."

sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF


sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

echo "K8s Installed...sucessfully"

kubeadm version
kubelet --version

echo "Bash.......... Execute sucessfully"




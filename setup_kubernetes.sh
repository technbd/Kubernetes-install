#!/bin/bash

# set -e 

###Disable Swap Space all Nodes(Master and Worker):
# sudo swapoff –a

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


###Installing docker on official repo and Add Docker's official GPG key:
echo "Docker Install..."
sudo apt update
sudo apt install curl ca-certificates apt-transport-https software-properties-common
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl start containerd

echo "Docker Installed...sucessfully"

###Install Docker on Ubuntu from the Ubuntu repository:
# sudo apt install docker.io -y


echo "Containerd Configuring..."

sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml


sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd


###Installing Kubernetes:
echo "K8s Install..."
sudo apt update
sudo apt install -y curl ca-certificates apt-transport-https

sudo curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo apt-key add -
sudo echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
#sudo echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Hold Packages List:"
sudo apt-mark showhold

echo "K8s Installed...sucessfully"
kubeadm version
kubelet --version

echo "Bash.......... Execute sucessfully"



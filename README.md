## Kubernetes Made Easy: Quick kubeadm Installation Guide:

To create a Kubernetes cluster using kubeadm, you need to follow a series of steps. Here's a simplified guide:

### Prerequisites:
- At least 2 or more Linux machines (VMs or physical servers) with Ubuntu, CentOS, or any other supported OS.
- Disable swap on all nodes.
- Install Docker on all nodes.
- Each machine should have a static IP address.
- Set up a unique hostname, MAC address, and product_uuid for each machine.
- Open necessary ports (6443, 16443, 2379-2380, 10250, 10251, 10252, 30000-32767) in your firewall.


### Turn Off Swap Memory:

Before proceeding, it's a good idea to verify the current status of swap space. You can do this by running the "**free -h**" command, which displays memory and swap space usage. To temporarily disable swap, you can use the "swapoff". 

To permanently disable swap space in a Linux system, you'll need to modify the system's configuration files. Edit the "/etc/fstab" file contains configuration information for filesystems and swap space. 

```
sudo swapoff -a
```


## Run the script:

**On Master Node:**

This script will automate the installation of Docker, Kubernetes components (kubeadm, kubelet, kubectl) and etc. To install a container runtime into each node in the cluster so that Pods can run there. 

**Note:** Dockershim has been removed from the Kubernetes project as of release 1.24.

```
sudo chmod +x setup_kubernetes.sh

bash setup_kubernetes.sh
```

**If you want to perform actions after the successful execution of the bash script, you can check the status:** 


```
systemctl status docker
```


```
systemctl status containerd
```


### Systemd cgroup driver Check:

If you installed containerd from a package (for example, RPM or .deb), you may find that the CRI integration plugin is disabled by default. 

You need CRI support enabled to use containerd with Kubernetes. Make sure that cri is not included in the disabled_plugins list within /etc/containerd/config.toml; if you made changes to that file, also restart containerd.

```
grep SystemdCgroup /etc/containerd/config.toml
grep disabled_plugins /etc/containerd/config.toml
```


### Initialize the cluster:

**On Master Node:**

On the master node, initialize the cluster using kubeadm and Kubernetes cluster which will give you the token or command to connect with this Master node from the Worker node.


```
sudo kubeadm init


### For flannel:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```


```
Outputs: 

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

...
...

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join master_node_ip:6443 --token 12345l2.bzlsnlt6xxxxxxxxxx \
        --discovery-token-ca-cert-hash sha256:12959e5591a6604992a79xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

```



### Set up kubeconfig:

**On Master Node:**
Run the following commands on the master node to set up kubeconfig:

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


```
systemctl status kubelet
systemctl enable kubelet
```


```
ll /etc/kubernetes/
ll /etc/kubernetes/manifests
ll /var/lib/kubelet/config.yaml
```


```
kubeadm config images list
```


```
sudo kubeadm certs check-expiration
sudo kubeadm certs certificate-key
```




```
kubectl get --raw='/readyz?verbose'
```


```
kubectl get componentstatus
kubectl get cs
```


```
kubectl get nodes
```


```
kubectl get pods -n kube-system
```


```
kubectl get pods -A
kubectl get pods --all-namespaces
```


```
kubectl cluster-info
```


```
kubectl config view
```

```
kubectl api-resources
```




### Install Network Plugin:

**On Master Node:**
Choose a network plugin for pod networking. For example, you can use Calico or Flannel. Install the chosen plugin using:


**Calico:**
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
```


**Flannel:**
```
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```


```
kubectl get pod -A

NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-658d97c59c-hq87h   1/1     Running   0          5m41s
kube-system   calico-node-ns7q7                          1/1     Running   0          5m41s
kube-system   coredns-5dd5756b68-487vt                   1/1     Running   0          17m
kube-system   coredns-5dd5756b68-8jldd                   1/1     Running   0          17m
kube-system   etcd-node01                                1/1     Running   0          17m
kube-system   kube-apiserver-node01                      1/1     Running   0          17m
kube-system   kube-controller-manager-node01             1/1     Running   0          17m
kube-system   kube-proxy-tkj5q                           1/1     Running   0          17m
kube-system   kube-scheduler-node01                      1/1     Running   0          17m
```


```
kubectl logs <pod_name>
kubectl logs -f <pod_name>
```


## Join the worker nodes in the cluster:

**On Worker Node:**

On each worker node, run the kubeadm join command generated after the "kubeadm init" command. It will look something like this:

```
sudo kubeadm join <master_node_ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

This command will take some time to complete and will generate a command to join nodes to the cluster.



### Manual Token Create:

**On Master Node:**

```
kubeadm token list
kubeadm token create --print-join-command
```


```
kubeadm token delete <TOKEN>
```



### Verify:

**On Master Node:**

On the master node, check if all nodes are ready:

```
kubectl get nodes

NAME     STATUS   ROLES           AGE   VERSION
node01   Ready    control-plane   44m   v1.28.2
node02   Ready    <none>          45s   v1.28.2
```



### Resetting a Cluster:

To reset kubeadm and your Kubernetes cluster, you can use the kubeadm reset command. This command is used to revert any changes made to a host by kubeadm init or kubeadm join. This ensures that any Kubernetes configuration files are completely removed.

```
sudo kubeadm reset --force
```

```
sudo rm -rf /etc/cni/net.d
sudo rm -rf ~/.kube/
```



### Configuring kubectl on the client machine:

**On Master Node:**

```
sudo chmod +r /etc/kubernetes/admin.conf
```

**From client machine**

```
cd /etc/kubernetes
scp user_name@master_node_ip:/etc/kubernetes/admin.conf .
```


**From client machine**

```
mkdir ~/.kube
mv admin.conf ~/.kube/config
chmod 600 ~/.kube/config
```


```
kubectl get nodes
```


**On Master Node:**

```
sudo chmod 600 /etc/kubernetes/admin.conf
```


### Kubernetes Bash Completion:

Enabling bash completion for Kubernetes commands can greatly improve your productivity when working with kubectl and other Kubernetes-related tools. Here's how you can set it up:


```
sudo apt install -y bash-completion
```

```
echo $SHELL
```


```
kubectl completion bash
```


```
cd ~/.kube/
kubectl completion bash > kubecom.sh
```


```
ll $HOME/.kube/kubecom.sh
source $HOME/.kube/kubecom.sh
```


### Links:
- [Kubernetes Install](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Kubernetes cgroup driver](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/)
- [Kubernetes Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd/)
- [Kubernetes CRI Setup](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)




Congratulations! You have successfully set up a Kubernetes cluster using kubeadm. You can now deploy and manage containerized applications on your cluster.












## K0s Kubernetes:

k0s is a lightweight, open-source Kubernetes distribution created by Mirantis, designed to be a zero-friction, all-inclusive Kubernetes distribution.

**"k0s" stands for "zero"** — zero dependencies, zero OS requirements, zero cost (open source), and zero complexity compared to vanilla Kubernetes.



### Key Features:


#### Single Binary Distribution: 
- Entire control plane packaged as a single binary (~200MB)
- No external dependencies required on the host
- Works without a package manager


#### Minimal Resource Footprint:
- Runs on as little as 1 CPU core and 1GB RAM
- Great for edge computing and resource-constrained environments


#### Supports Multiple Architectures:
- x86-64, ARM64, ARMv7
- Ideal for IoT and edge devices


#### Built-in Containerd:
- Uses containerd as the container runtime (CRI-compliant)
- No Docker dependency


#### Flexible Networking (CNI):
- Ships with Konnectivity for control plane ↔ worker communication
- Supports multiple CNI plugins: Calico (default), Kuberouter, custom CNIs


#### Air-gapped / Offline Support: 
- Can be deployed in fully isolated environments



### Architecture:

```
Control Plane Node
├── kube-apiserver
├── kube-scheduler
├── kube-controller-manager
├── etcd (embedded or external)
└── konnectivity-server

Worker Node
├── kubelet
├── kube-proxy
├── containerd
└── konnectivity-agent
```


### Kubeadm vs K0s: 

Unlike `kubeadm` where the master runs a `kubelet` and taints itself, `k0s` controller is **purely a control plane process** — no kubelet, no node registration.


| Behavior | kubeadm | k0s |
| -------- | ------- | --- |
| Master shows in get nodes |✅ yes |❌ no (by design) |
| Master runs kubelet| ✅ yes | ❌ no | 
| Master runs workloads |⚠️ tainted | ❌ never (default) | 
| Control plane isolation | partial | strict |




### Prerequisites:
- Host operating system: 
    - Amazon Linux 2023
    - Alpine Linux
    - CentOS Stream 9/10
    - Red Hat Enterprise Linux	7.9
    - Rocky Linux 8.10
    - Ubuntu	(20.04 LTS, 22.04 LTS, 24.04)
    - Debian GNU/Linux 11/12 
- Architecture: 
    - x86_64, 
    - aarch64 
    - armv7l
    - riscv64





---
---



## Install k0s:

Instead of installing many system components separately (like etcd, kubelet setup, container runtime config, CNI setup), k0s ships everything in a **single binary.**


### Download k0s:

Run the k0s download script to download the latest stable version of k0s and make it executable from /usr/local/bin/k0s.

```
curl --proto '=https' --tlsv1.2 -sSf https://get.k0s.sh | sudo sh
```


```
ll /usr/local/bin

-rwxr-xr-x 1 root root 259779282 Jun 10 17:50 k0s
```


```
k0s version

v1.35.4+k0s.0
```



### Create a single-node cluster (controller + worker):

```
k0s install controller --single
```


_Start k0s service:_
```
k0s start
```


### Verify the Cluster Status: 

_Check status:_
```
k0s status


Version: v1.35.4+k0s.0
Process ID: 763
Role: controller
Workloads: true
SingleNode: true
Kube-api probing successful: true
Kube-api probing last error:
```


```
k0s kubectl get nodes
k0s kubectl get nodes -o wide

NAME   STATUS   ROLES           AGE     VERSION
bm01   Ready    control-plane   2m13s   v1.35.4+k0s
```


```
k0s kubectl get pods -A


NAMESPACE     NAME                             READY   STATUS    RESTARTS   AGE
kube-system   coredns-5cc4b78c7c-fsj5w         1/1     Running   0          2m30s
kube-system   kube-proxy-c8zgx                 1/1     Running   0          2m29s
kube-system   kube-router-p8p4f                1/1     Running   0          2m29s
kube-system   metrics-server-df68c566c-gmtvl   1/1     Running   0          2m28s
```


```
k0s kubectl get ns

NAME              STATUS   AGE
default           Active   33m
k0s-autopilot     Active   33m
kube-node-lease   Active   33m
kube-public       Active   33m
kube-system       Active   33m
```



_Export the kubeconfig:_
```
k0s kubeconfig admin > ~/.kube/config

scp -r .kube/config root@<local_pc_ip>:~/.kube/config
chmod 600 ~/.kube/config
```




### Uninstall k0s:
The removal of k0s is a two-step process. Then reboot the system.


_Stop the service:_
```
k0s stop
```


_The `k0s reset` command cleans up the installed system service, data directories, containers, mounts and network namespaces:_
```
k0s reset
```



---
---


## Create the Deployment:

To deploy and run Nginx on your newly installed k0s Kubernetes cluster: 

```
k0s kubectl create deployment nginx-demo --image=nginx
```


```
k0s kubectl get pods

NAME                          READY   STATUS    RESTARTS   AGE
nginx-demo-5c86c7d69f-49x7x   1/1     Running   0          53s
```


_Expose Nginx to external traffic:_
```
k0s kubectl expose deployment nginx-demo --type=NodePort --port=80 --dry-run=client -o yaml
k0s kubectl expose deployment nginx-demo --type=NodePort --port=80
```


_Find the Assigned Port:_
```
k0s kubectl get service nginx-demo

NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-demo   NodePort   10.99.245.54   <none>        80:32632/TCP   14s
```


_Test it out:_
```
curl http://localhost:32632
```





---
---



## Troubleshooting:

_Run k0s preflight check:_
```
k0s sysinfo | grep -i groups


Error: sysinfo failed
  Control Groups: version 1 (rejected: cgroup v1 is not supported)
  CONFIG_CGROUPS: Control Group support: built-in (pass)

```


_Verify Current Cgroup Version:_
```
stat -fc %T /sys/fs/cgroup/

tmpfs
```


### Enable Cgroup v2:

#### Option 1 — GRUB bootloader (most common):

_Edit `/etc/default/grub` and Find the` GRUB_CMDLINE_LINUX` line and add `systemd.unified_cgroup_hierarchy=1`:_
```
GRUB_CMDLINE_LINUX="... systemd.unified_cgroup_hierarchy=1"
```


_Then update GRUB and reboot:_
```
# RHEL/CentOS/Rocky:
grub2-mkconfig -o /boot/grub2/grub.cfg

# Ubuntu/Debian:
update-grub


reboot
```


#### Option 2 — If using RHEL 8 / CentOS 8 / Rocky 8:

```
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
```


```
reboot
```


_Check cgroup v2 is active_
```
stat -fc %T /sys/fs/cgroup/

cgroup2fs
```




### Check k0s Status: 


_Check if the service is actually running:_
```
systemctl status k0scontroller
```


```
systemctl start k0scontroller
```


_Check the logs for errors:_
```
journalctl -u k0scontroller -f
```



--- 
--- 


### Ref: 
- [K0s Docs](https://docs.k0sproject.io/stable/)
- [K0s Installation](https://docs.k0sproject.io/stable/install/)
- [K0s | github.com](https://github.com/k0sproject/k0s)




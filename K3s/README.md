## Install K3s Kubernetes Cluster:

K3s is a lightweight, easy-to-install, and certified Kubernetes distribution designed for production workloads in resource-constrained environments. Developed by Rancher Labs, K3s aims to provide a fully compliant Kubernetes distribution that is simple to deploy, yet powerful enough for various use cases.

After running this installation:
- K3s provides a built-in `kubectl` utility.
- Additional utilities will be installed, including `kubectl`, `crictl`, `ctr`, `k3s-killall.sh`, and `k3s-uninstall.sh`
- A kubeconfig file will be written to `/etc/rancher/k3s/k3s.yaml` and the `kubectl` installed by K3s will automatically use it.
- The available lightweight datastore based on `sqlite3` as the default storage backend (also support etcd3, MySQL, and Postgres).
- By default, K3S will run with `flannel` as the CNI, using VXLAN as the default backend.


### Prerequisites:
Before installing K3s, make sure your system meets the following minimum system requirements: 
- OS: Ubuntu/Debian, CentOS, RHEL and Raspberry Pi.
- CPU 2 cores
- RAM 2 GB
- Docker/Containerd
- Disable swap on your system
- K3s server needs port `6443` to be accessible by all nodes.
- Disable the firewall or allow the necessary ports: `6443`, `10250`, `2379` and `8472/udp`

- If you wish to utilize the metrics server, all nodes must be accessible to each other on port `10250`.

- If you plan on achieving high availability with embedded etcd, server nodes must be accessible to each other on ports `2379` and `2380`.
- The nodes need to be able to reach other nodes over UDP port `8472` when using the Flannel VXLAN backend.

- Check the K3s documentation for a comprehensive list of required ports.



#### Inbound Rules for K3s Nodes:

K3s Required Network Ports:

| Protocol | Port      | Source    | Destination | Description                                              |
| -------- | --------- | --------- | ----------- | -------------------------------------------------------- |
| TCP      | 2379 – 2380 | Servers   | Servers     | Required only for HA with embedded etcd                  |
| TCP      | 6443      | Agents    | Servers     | K3s supervisor and Kubernetes API Server                 |
| UDP      | 8472      | All nodes | All nodes   | Required only for Flannel VXLAN                          |
| TCP      | 10250     | All nodes | All nodes   | Kubelet metrics                                          |
| UDP      | 51820     | All nodes | All nodes   | Required only for Flannel WireGuard (IPv4)               |
| UDP      | 51821     | All nodes | All nodes   | Required only for Flannel WireGuard (IPv6)               |
| TCP      | 5001      | All nodes | All nodes   | Required only for embedded distributed registry (Spegel) |
| TCP      | 6443      | All nodes | All nodes   | Required only for embedded distributed registry (Spegel) |





### Set Hostname:

```
hostnamectl set-hostname master
hostnamectl set-hostname worker1
hostnamectl set-hostname worker2
```


## Step-by-Step Install K3s:

### Install K3s:

_On Master node:_
```
curl -sfL https://get.k3s.io | sh -
```



### Install K3s without ingress `traefik` controller:

You can use a combination of `INSTALL_K3S_EXEC`, `K3S_` environment variables, and **command flags to pass configuration** to the service configuration. 

_Environment Variables options:_
- `--agent-token`
- `--cluster-cidr`
- `--cluster-dns`
- `--cluster-domain`
- `--disable-cloud-controller`
- `--disable-helm-controller`
- `--disable-network-policy`
- `--disable=servicelb` Note: other packaged components may be disabled on a per-server basis
- `--egress-selector-mode`
- `--embedded-registry`
- `--flannel-backend`
- `--flannel-external-ip`
- `--flannel-ipv6-masq`
- `--secrets-encryption`
- `--secrets-encryption-provider`
- `--service-cidr`





_On Master node:_
```
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -s -


or,

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -
```



```
### Output: 

[INFO]  Finding release for channel stable
[INFO]  Using v1.33.6+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.33.6+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.33.6+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Skipping /usr/local/bin/ctr symlink to k3s, command exists in PATH at /usr/bin/ctr
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s
```



### Check K3s Master status: 

```
systemctl status k3s
```


```
k3s -version
```


```
kubectl version


### If Need: 
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
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


```
kubectl get cs
kubectl get componentstatus
```


```
ps fxa | grep containerd
```


```
ll /var/lib/rancher/k3s/server/manifests

-rw------- 1 root root 1914 Dec 14 07:17 ccm.yaml
-rw------- 1 root root 5167 Dec 14 07:17 coredns.yaml
-rw------- 1 root root 3350 Dec 14 07:17 local-storage.yaml
drwx------ 2 root root 4096 Dec 14 07:17 metrics-server/
-rw------- 1 root root 1737 Dec 14 07:17 rolebindings.yaml
-rw------- 1 root root  927 Dec 14 07:17 runtimes.yaml
```



#### Check K3s pod networking:

```
## Check Network device flannel.1:

ifconfig flannel.1


## Check Bridge cni0:

ifconfig cni0
```



_CNI Network Configuration:_
```
cat /var/lib/rancher/k3s/agent/etc/cni/net.d/10-flannel.conflist
```


_Runtime Network State:_
```
cat /run/flannel/subnet.env
```



### Check the Cluster Nodes:

```
kubectl get nodes
kubectl get nodes -o wide

NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,master   24m   v1.33.6+k3s1
```



### Check the Cluster Pods:

```
kubectl get pod -A

NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-6d668d687-v8b9j                   1/1     Running   0          24m
kube-system   local-path-provisioner-869c44bfbd-drhgg   1/1     Running   0          24m
kube-system   metrics-server-7bfffcd44-r4tdz            1/1     Running   0          24m
```


```
kubectl get deploy -A
```


```
kubectl get ns


NAME              STATUS   AGE
default           Active   25m
kube-node-lease   Active   25m
kube-public       Active   25m
kube-system       Active   25m
```


```
kubectl get pods -n kube-system
```



### Check the Cluster Services:

```
kubectl get svc -A 


NAMESPACE     NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default       kubernetes       ClusterIP   10.43.0.1       <none>        443/TCP                  25m
kube-system   kube-dns         ClusterIP   10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP   25m
kube-system   metrics-server   ClusterIP   10.43.176.104   <none>        443/TCP                  25m
```



## To add nodes to a K3s cluster: 

To install additional agent nodes and add them to the cluster, run the installation script with the `K3S_URL` and `K3S_TOKEN` environment variables. 

The K3s agent will register with the K3s server listening at the supplied URL. The value to use for `K3S_TOKEN` is stored at "`/var/lib/rancher/k3s/server/node-token`" on your server node.


_Here is an example showing how to join an agent:_
```
ll /var/lib/rancher/k3s/server/node-token

cat /var/lib/rancher/k3s/server/node-token
```


### Apply to worker nodes:
- `K3S_TOKEN` :	Token to use for authentication
- `K3S_URL` :	Server to connect to


``` 
curl -sfL https://get.k3s.io | K3S_URL=https://<k3s_server_ip>:6443 K3S_TOKEN=<my_token> sh -
```



```
### Output:

[INFO]  Finding release for channel stable
[INFO]  Using v1.33.6+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.33.6+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.33.6+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Skipping /usr/local/bin/ctr symlink to k3s, command exists in PATH at /usr/bin/ctr
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-agent-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s-agent.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s-agent.service
[INFO]  systemd: Enabling k3s-agent unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s-agent.service → /etc/systemd/system/k3s-agent.service.
[INFO]  systemd: Starting k3s-agent
```



### Check agent nodes status: 

```
systemctl status k3s-agent
```


_On Master node:_
```
kubectl get nodes


NAME      STATUS   ROLES                  AGE     VERSION
master    Ready    control-plane,master   67m     v1.33.6+k3s1
worker1   Ready    <none>                 7m47s   v1.33.6+k3s1
worker2   Ready    <none>                 6m52s   v1.33.6+k3s1
```




## For Normal (`sudo`) User: 

This is setting up `kubectl` access for a **non-root user**.

```
echo $USER
pwd

mkdir -p ~/.kube

sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config
sudo chmod 600 ~/.kube/config

ll ~/.kube/config

export KUBECONFIG=~/.kube/config
```


```
kubectl get nodes
kubectl get pods -A
```





## To uninstall K3s:

### To uninstall K3s from a `server` node, run:

```
ll /usr/local/bin/k3s-uninstall.sh

/usr/local/bin/k3s-uninstall.sh
```



### To uninstall K3s from an `agent` node, run:

```
ll /usr/local/bin/k3s-agent-uninstall.sh

/usr/local/bin/k3s-agent-uninstall.sh
```




### Links:
- [K3s Install](https://docs.k3s.io/quick-start)
- [K3s with install script](https://docs.k3s.io/installation/configuration)
- [k3s Environment Variables](https://docs.k3s.io/reference/env-variables)
- [k3s server Values](https://docs.k3s.io/cli/server)
- [k3s agent Values](https://docs.k3s.io/cli/agent)

That's it! You now have a basic K3s Kubernetes cluster up and running. Make sure to consult the official K3s documentation for any specific requirements or advanced configurations you might need for your setup.




## MetalLB:

MetalLB is a load balancer implementation for Kubernetes cluster. It helps to enable the use of standard network load-balancers in environments where the Kubernetes cluster is deployed, such as on-premises setups or in cloud environments that do not provide native load balancer integration.


This will deploy MetalLB to your cluster, under the metallb-system namespace. The components in the manifest are:

- The metallb-system/controller deployment. This is the cluster-wide controller that handles IP address assignments.
- The metallb-system/speaker daemonset. This is the component that speaks the protocol(s) of your choice to make the services reachable.
- Service accounts for the controller and speaker, along with the RBAC permissions that the components need to function.




### Enable strict ARP mode: 

If you’re using `kube-proxy` in IPVS (IP Virtual Server) mode, since Kubernetes v1.14.2 you have to enable strict ARP mode. 
Note, you don’t need this if you’re using kube-router as service-proxy because it is enabling strict ARP by default.

This is a required network fix when using MetalLB with `kube-proxy` in IPVS mode. Without it, LoadBalancer services will NOT work correctly.
- `strictARP: true` prevents multiple Kubernetes nodes from replying to ARP requests for the same LoadBalancer IP, which is mandatory for MetalLB + IPVS.
- The strictARP requirement applies to:
    - kubeadm clusters
    - kube-proxy running in IPVS mode

- In standard Kubernetes (kubeadm): kube-proxy runs as a DaemonSet. 
- In K3s: kube-proxy is embedded inside the K3s binary. So there is NO kube-proxy pod. 
- You DO NOT need strictARP in your case because:
    - K3s uses iptables mode
    - IPVS is not enabled by default
    - MetalLB works fine without strictARP in iptables mode




_Edit kube-proxy config:_
```
kubectl edit configmap -n kube-system kube-proxy
```


```
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```



### 1. Install MetalLB manifests (CRDs + controllers):


**You can install MetalLB using Kubernetes manifests directly.**

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml


or,

wget https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

kubectl apply -f metallb-native.yaml
```


```
kubectl get ns

NAME              STATUS   AGE
metallb-system    Active   69s
```


```
kubectl get deploy -n metallb-system

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
controller   1/1     1            1           4h13m
```


```
kubectl get pods -n metallb-system

NAME                          READY   STATUS    RESTARTS   AGE
controller-5f56cd6f78-sqrss   1/1     Running   0          45s
speaker-hsrn4                 1/1     Running   0          45s
speaker-9k9xj                 1/1     Running   0          45s
speaker-wd4xq                 1/1     Running   0          45s
```


```
kubectl get svc -n metallb-system


NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
webhook-service   ClusterIP   10.43.212.209   <none>        443/TCP   8m17s
```



### 2. Check that CRDs exist:


```
kubectl get crds | grep metallb


bfdprofiles.metallb.io            2025-12-14T10:08:20Z
bgpadvertisements.metallb.io      2025-12-14T10:08:20Z
bgppeers.metallb.io               2025-12-14T10:08:20Z
communities.metallb.io            2025-12-14T10:08:20Z
ipaddresspools.metallb.io         2025-12-14T10:08:20Z
l2advertisements.metallb.io       2025-12-14T10:08:20Z
```



### 3. MetalLB Configure:

MetalLB remains idle until configured. This is accomplished by creating and deploying various resources into the same namespace (`metallb-system`) MetalLB is deployed into.


#### Address-pool Configure:

By default, MetalLB will allocate IPs from any configured address pool with free addresses. This might end up using “expensive” addresses for services that don’t require it.

To specify a single IP address in a pool, use /32 in the CIDR notation (e.g. 42.176.25.64/32).

To prevent this behaviour you can disable automatic allocation for a pool by setting the autoAssign flag to false:


```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.10.193-192.168.10.194
```


```
kubectl apply -f metallb-ipaddresspool.yaml
```


```
kubectl get IPAddressPool -n metallb-system

NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["192.168.10.193-192.168.10.194"]
```



#### L2-Advertisement:

Normally, all the nodes where a Speaker is running are eligible for any given IP.

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```


```
kubectl apply -f metallb-l2advertisement.yaml
```


```
kubectl get L2Advertisement -n metallb-system

NAME      IPADDRESSPOOLS   IPADDRESSPOOL SELECTORS   INTERFACES
example   ["first-pool"]
```



### Links:
- [MetalLB Install](https://metallb.universe.tf/installation/)
- [MetalLB AddressPool](https://metallb.universe.tf/configuration/_advanced_ipaddresspool_configuration/)
- [MetalLB L2Advertisement](https://metallb.universe.tf/configuration/_advanced_l2_configuration/)


Apply this service definition to your cluster, and MetalLB will allocate an external IP address from the configured pool to this service.

That's it! You've successfully installed and configured MetalLB on your Kubernetes cluster. You can now use it to allocate external IP addresses to your services.


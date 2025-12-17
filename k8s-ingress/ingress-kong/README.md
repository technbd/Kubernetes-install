## Kong Ingress Controller (KIC):

Kong Ingress Controller (KIC) is a Kubernetes-native application that integrates Kong Gateway with Kubernetes. It allows you to manage your Ingress traffic using Kong’s powerful API Gateway features, such as:
- Load balancing
- Authentication
- Rate limiting
- Logging and monitoring
- Service mesh integration (via Kuma or Kong Mesh)

It acts as a bridge between Kubernetes Ingress resources and Kong Gateway, making Kong the entry point for your cluster traffic.





_KIC consists of:_

1. Kong Gateway:
    - The actual reverse proxy / API gateway that handles requests.

2. Kong Ingress Controller:
    - Watches Kubernetes resources and updates Kong Gateway dynamically.
    - Usually runs as a Deployment inside the cluster.

3. Custom Resource Definitions (CRDs):
    - KongPlugin, KongIngress, KongConsumer, KongCredential.





## Install Kong:

### Using Helm (Recommended):

_Create a namespace for Kong:_
```
kubectl create namespace kong
```


_Add a Kong Helm repo:_
```
helm repo add kong https://charts.konghq.com
helm repo update
```


```
helm search repo kong
```


_Install the Gateway API CRDs before installing Kong Ingress Controller:_
```
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

Or,

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
```



```
kubectl get crd | grep kong
```


_If delete:_
```
kubectl delete crd $(kubectl get crd | grep kong | awk '{print $1}')
```



_Install Kong Ingress Controller with a `LoadBalancer` or `NodePort`:_
- `proxy.type=NodePort` → local dev
- `proxy.type=LoadBalancer` → cloud (AWS, GCP)

```
helm install kong kong/kong -n kong --set ingressController.installCRDs=false --set proxy.type=LoadBalancer

helm install kong kong/kong -n kong --set ingressController.enabled=true --set ingressController.installCRDs=false --set proxy.type=LoadBalancer

helm install kong kong/kong -n kong --set ingressController.enabled=true --set ingressController.installCRDs=false --set proxy.enabled=true --set proxy.type=LoadBalancer --set gatewayController.enabled=true --set gateway.enabled=true
```



```
helm get values kong -n kong

USER-SUPPLIED VALUES:
gateway:
  enabled: true
gatewayController:
  enabled: true
ingressController:
  enabled: true
  installCRDs: false
proxy:
  enabled: true
  type: LoadBalancer
```





```
kubectl get deploy -n kong

NAME        READY   UP-TO-DATE   AVAILABLE   AGE
kong-kong   1/1     1            1           5m33s
```



```
kubectl get pods -n kong

NAME                         READY   STATUS    RESTARTS   AGE
kong-kong-6c85bfb58f-brd6t   2/2     Running   0          6m8s
```



```
kubectl get svc -n kong

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP                                    PORT(S)                         AGE
kong-kong-manager              NodePort       10.43.255.194   <none>                                         8002:31459/TCP,8445:31993/TCP   23m
kong-kong-metrics              ClusterIP      10.43.49.121    <none>                                         10255/TCP,10254/TCP             23m
kong-kong-proxy                LoadBalancer   10.43.150.236   192.168.10.190,192.168.10.191,192.168.10.192   80:30498/TCP,443:32174/TCP      23m
kong-kong-validation-webhook   ClusterIP      10.43.225.64    <none>                                         443/TCP                         23m
```





```
kubectl get secrets -n kong

NAME                                      TYPE                 DATA   AGE
kong-kong-validation-webhook-ca-keypair   kubernetes.io/tls    2      11m
kong-kong-validation-webhook-keypair      kubernetes.io/tls    2      11m
sh.helm.release.v1.kong.v1                helm.sh/release.v1   1      11m
```


```
kubectl get validatingwebhookconfigurations -n kong

NAME                         WEBHOOKS   AGE
kong-kong-kong-validations   3          11m
```



```
kubectl get ingressClass

NAME   CONTROLLER                            PARAMETERS   AGE
kong   ingress-controllers.konghq.com/kong   <none>       10m
```



```
kubectl get gatewayclass


```




## Deploying App and Expose the App:

_Create Deployment:_
```
kubectl create deployment webapp-wear --image kodekloud/ecommerce:apparels
```


```
kubectl create deployment webapp-video --image kodekloud/ecommerce:video --replicas 2
```



_Expose Deployment:_
```
kubectl expose deploy webapp-wear --name=webapp-wear-svc --type=NodePort --port=8080 --target-port=8080
```


```
kubectl expose deploy webapp-video --name=webapp-video-svc --type=NodePort --port=8080 --target-port=8080
```


```
kubectl get svc

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes         ClusterIP   10.43.0.1       <none>        443/TCP          51m
webapp-video-svc   NodePort    10.43.238.140   <none>        8080:30194/TCP   19m
webapp-wear-svc    NodePort    10.43.90.23     <none>        8080:30340/TCP   20m
```




## Ingress and Gateway API: 

### Ingress vs Gateway API (Kong Perspective): 

| Feature             | **Ingress** (Kong Ingress Controller) |**Gateway API** (Kong Gateway Controller) |
| ------------------- | --------------------------------- | ------------------------------------- |
| Kubernetes maturity | **Stable / legacy**               | **Next-gen standard**                 |
| Routing model       | Flat, limited                     | **Role-based & extensible**           |
| TLS handling        | Annotations                       | **First-class**                       |
| Multi-team support  | Hard                              | **Designed for it**                   |
| Kong plugins        | Annotations                       | **Policy attachments (cleaner)**      |
| Protocol support    | Mostly HTTP                       | **HTTP, HTTPS, TCP, UDP, gRPC**       |
| Future investment   | Maintenance mode                  | **Active development**                |
| Recommendation      | Existing clusters                 | **New deployments**                   |




### Creating an Ingress Resources:

- Traditional or Legacy `Ingress`
- Modern `Gateway API` (from v3.0+)



#### Architecture: 

```
Client
   │
   ▼
Kong Proxy (LoadBalancer)
   │
   ▼
Ingress (Annotations + rules)
   │
   ▼
Service (ClusterIP)
   │
   ▼
Deployment Pods (App containers)

```



_Create a Legacy Ingress resources file `ingress-resources-host.yaml`:_
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host-based
  #namespace: default
  annotations:
    konghq.com/plugins: kong-rate-limit    # Plugin names referenced in KongPlugin resources
    #konghq.com/strip-path: "false"
    #konghq.com/methods: "GET, POST"
    #kubernetes.io/ingress.class: kong

spec:
  ingressClassName: kong
  rules:
  - host: "wear.idea.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-wear-svc  #service1
            port:
              number: 8080         #Port exposed by your Service

  - host: "watch.idea.com"
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-video-svc  #service2
            port:
              number: 8080
---
## kong-rate-limit:
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: kong-rate-limit     # Must match name in Ingress annotation
  #namespace: default
  annotations:
    kubernetes.io/ingress.class: kong
plugin: rate-limiting
config:
  minute: 100     # Number of requests allowed per minute
  policy: local
```



```
kubectl apply -f ingress-resources-host.yaml -o yaml --dry-run=client
kubectl apply -f ingress-resources-host.yaml
```





```
kubectl get ingress

NAME                 CLASS   HOSTS                          ADDRESS                                        PORTS   AGE
ingress-host-based   kong    wear.idea.com,watch.idea.com   192.168.10.190,192.168.10.191,192.168.10.192   80      8m12s
```




### Creating Kong Gateway API:


#### Architecture: 
```
Client
  ↓
Kong LoadBalancer (kong-proxy)
  ↓
Gateway (kong-gateway)
  ↓
HTTPRoute
  ↓
Service
  ↓
Deployment (Pods)
```


#### Gateway Class: 

```
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: kong
  annotations:
    konghq.com/gatewayclass-unmanaged: "true"
spec:
  controllerName: konghq.com/kic-gateway-controller
```


```
kubectl apply -f gatewayClass.yaml
```


```
kubectl get gatewayclass

NAME   CONTROLLER                          ACCEPTED   AGE
kong   konghq.com/kic-gateway-controller   True       6s
```




#### Gateway (Kong entry point):

```
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: kong-gateway
  namespace: kong
spec:
  gatewayClassName: kong
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
```


```
kubectl apply -f gateway.yaml
```


```
kubectl get gateway -n kong

NAME           CLASS   ADDRESS          PROGRAMMED   AGE
kong-gateway   kong    192.168.10.192   True         83m
```



#### HTTPRoute (expose the service): 

```
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: video-route
  namespace: default
spec:
  parentRefs:
  - name: kong-gateway
    namespace: kong
  hostnames:
    - watch.idea.com
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: webapp-video-svc
      kind: Service
      port: 8080
```


```
kubectl apply -f http-route.yaml
```


```
kubectl get httproute

NAME          HOSTNAMES            AGE
video-route   ["watch.idea.com"]   37s
```


_Get Kong external IP:_
```
kubectl get svc -n kong kong-kong-proxy

```



#### Access the application:

```
curl http://<EXTERNAL-IP>
```




### Ref: 

- [github.com/Kong](https://github.com/Kong/kubernetes-ingress-controller)




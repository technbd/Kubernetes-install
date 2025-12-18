## Traefik:

Traefik is a modern, open-source reverse proxy and load balancer that simplifies deploying microservices and APIs, especially in cloud-native environments like Kubernetes. It dynamically discovers your services, automatically handles SSL certificates (Let's Encrypt), routes traffic, and offers features like API gateway, security (WAF), and monitoring, all with minimal configuration and real-time updates. 


Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster. Traffic routing is controlled by rules defined on the Ingress resource.
  
While Pods within a Kubernetes cluster can easily communicate between themselves, they are not by default accessible to external networks and traffic. A Kubernetes Ingress is an API object that shows how traffic from the internet should reach internal Kubernetes cluster Services that send requests to groups of Pods. 




### Key Concepts in Traefik:

_Traefik revolves around four key building blocks:_

- **EntryPoints**: Define the network ports (e.g., HTTP/HTTPS) through which Traefik receives incoming traffic.
- **Routers**: Match incoming requests and direct them to the appropriate service based on defined rules.
- **Middlewares**: Transform requests or responses before they are processed by the service (e.g., adding headers, authentication, rate-limiting).
- **Services**: Represent the actual backend services that respond to requests.




## Installing Traefik as Ingress Controller:


_Add a traefik Helm repo:_
```
helm repo add traefik https://traefik.github.io/charts
helm repo update
```


```
helm search repo traefik
```


_Get Default Configuration:_
```
helm show values traefik/traefik | less

helm show values traefik/traefik > values.yaml
```



```
helm search repo traefik

helm pull traefik/traefik --untar
```



_Create a namespace for traefik:_
```
kubectl create namespace traefik
```




_Install Traefik Ingress Controller:_

- `dashboard.enabled=true` → activates the dashboard.
- `dashboard.ingressRoute=true` → allows exposing it via an IngressRoute.
- `service.type=ClusterIP` or `LoadBalancer` → default internal service.


```
helm install traefik traefik/traefik -n traefik

helm install traefik traefik/traefik -n traefik --set crds.enabled=true --set dashboard.enabled=true --set dashboard.ingressRoute=true --set providers.kubernetesIngress.enabled=true --set service.type=LoadBalancer
```


```
helm get values traefik -n traefik

USER-SUPPLIED VALUES:
crds:
  enabled: true
dashboard:
  enabled: true
  ingressRoute: true
providers:
  kubernetesIngress:
    enabled: true
service:
  type: LoadBalancer
```



```
kubectl get crds | grep traefik
```



```
kubectl get deploy -n traefik

NAME      READY   UP-TO-DATE   AVAILABLE   AGE
traefik   1/1     1            1           69s
```


```
kubectl get pods -n traefik

NAME                       READY   STATUS    RESTARTS   AGE
traefik-59ddf46749-xxjsz   1/1     Running   0          82s
```


```
kubectl get svc -n traefik

NAME      TYPE           CLUSTER-IP     EXTERNAL-IP                                    PORT(S)                      AGE
traefik   LoadBalancer   10.43.103.40   192.168.10.190,192.168.10.191,192.168.10.192   80:30113/TCP,443:32406/TCP   28s
```



```
kubectl get secrets -n traefik

NAME                            TYPE                 DATA   AGE
sh.helm.release.v1.traefik.v1   helm.sh/release.v1   1      112s
```



```
kubectl get ingressClass

NAME      CONTROLLER                      PARAMETERS   AGE
traefik   traefik.io/ingress-controller   <none>       2m14s
```



## Deploying App and Expose the App:

```
kubectl create deployment webapp-wear --image kodekloud/ecommerce:apparels
kubectl create deployment webapp-video --image kodekloud/ecommerce:video --replicas 2
```


```
kubectl expose deploy webapp-wear --name=webapp-wear-svc --type=NodePort --port=8080 --target-port=8080
kubectl expose deploy webapp-video --name=webapp-video-svc --type=NodePort --port=8080 --target-port=8080
```


```
kubectl get svc

NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes         ClusterIP   10.43.0.1       <none>        443/TCP          6h3m
webapp-video-svc   NodePort    10.43.238.140   <none>        8080:30194/TCP   5h32m
webapp-wear-svc    NodePort    10.43.90.23     <none>        8080:30340/TCP   5h32m
```




## Creating an Ingress Resources:


_Create a Legacy Ingress resources file `ingress-resources-host.yaml`:_
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host-based
  #namespace:
  annotations:
    kubernetes.io/ingress.class: traefik

spec:
  ingressClassName: traefik
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
              number: 8080 

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
```


```
kubectl apply -f ingress-resources-host.yaml -o yaml --dry-run=client
kubectl apply -f ingress-resources-host.yaml
```


```
kubectl get ingress

NAME                 CLASS     HOSTS                          ADDRESS                                        PORTS   AGE
ingress-host-based   traefik   wear.idea.com,watch.idea.com   192.168.10.190,192.168.10.191,192.168.10.192   80      12s
```



### Access the application::

```
curl http://<your.domain.com>
```




## Exposing the Application Using an IngressRoute (CRD): 

```
Client (User Browser)
     |
     v
 DNS (watch.idea.com)
     |
     v
 Traefik LoadBalancer / NodePort
     |
     v
 IngressRoute  ← (THIS YAML)
     |
     v
 Kubernetes Service (webapp-video-svc)
     |
     v
 Pods (your app)
```



```
apiVersion: traefik.io/v1alpha1
#apiVersion: traefik.containo.us/v1alpha1     # Legacy v2.x (old) 
kind: IngressRoute
metadata:
  name: video-ingressroute     # your-ingressroute-name
  #namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`watch.idea.com`)       # change to your domain
      kind: Rule
      services:
        - name: webapp-video-svc          # change your service name
          port: 8080     
```


Or,

```
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: video-ingressroute     # your-ingressroute-name
  #namespace: default
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`watch.idea.com`)       # change to your domain
      kind: Rule
      services:
        - name: webapp-video-svc          # change your service name
          port: 8080
    - match: Host(`wear.idea.com`)       # change to your domain
      kind: Rule
      services:
        - name: webapp-wear-svc          # change your service name
          port: 8080

```



```
kubectl apply -f ingressroute.yaml
```


```
kubectl get ingressroute

NAME                 AGE
video-ingressroute   35s
```



### Access the application::

```
curl http://<your.domain.com>
```



## Exposing the Application Using the Gateway API:

Traefik supports the Kubernetes Gateway API specification, which provides a more standardized way to configure ingress in Kubernetes. When we installed Traefik earlier, we enabled the Gateway API provider. You can verify this in the providers section of the Traefik dashboard.

_Install the Gateway API CRDs in your cluster:_
```
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```


```
kubectl get crds | grep gateway
```



### 

```
helm install traefik traefik/traefik \
  -n traefik \
  --set crds.enabled=true \
  --set dashboard.enabled=true \
  --set dashboard.ingressRoute=true \
  --set providers.kubernetesGateway.enabled=true \
  --set providers.kubernetesGateway.entryPoints[0]=web \
  --set providers.kubernetesGateway.entryPoints[1]=websecure \
  --set providers.kubernetesIngress.enabled=true \
  --set service.type=LoadBalancer
```


### Gateway Class:

_GatewayClass for Traefik:_
```
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: traefik
spec:
  controllerName: traefik.io/gateway-controller
```


```
kubectl apply -f gatewayclass.yaml
```


```
kubectl get gatewayclass

NAME      CONTROLLER                      ACCEPTED   AGE
traefik   traefik.io/gateway-controller   True       9s
```



### Create Gateway:

```
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik-gateway
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```


```
kubectl apply -f gateway.yaml
```



```
kubectl get gateway -n traefik

NAME              CLASS     ADDRESS          PROGRAMMED   AGE
traefik-gateway   traefik   192.168.10.190   True         18s
```



### HTTPRoute: 

```
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: http-route
  namespace: default
spec:
  parentRefs:
  - name: traefik-gateway
    namespace: traefik
    sectionName: http
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
kubectl apply -f httproute.yaml
```


```
kubectl get httproute

NAME         HOSTNAMES            AGE
http-route   ["watch.idea.com"]   14s
```



## Expose Traefik Dashboard: 

Key points:
- `api@internal` → this is Traefik’s internal dashboard service.
- `Host(...)` → your domain or hostname for accessing the dashboard.


```
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard     # your-ingressroute-name
  namespace: traefik
spec:
  entryPoints:
    - web
  routes:
    - match: Host(`traefik.idea.com`)  # change to your domain
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
```



```
kubectl apply -f traefik-dashboard.yaml
```


```
kubectl get ingressroute -n traefik

NAME                AGE
traefik-dashboard   13s
```



### Access the Dashboard:

```
curl http://<your.domain.com>
```



### Ref:
- [Started with Kubernetes and Traefik](https://doc.traefik.io/traefik/getting-started/kubernetes/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)






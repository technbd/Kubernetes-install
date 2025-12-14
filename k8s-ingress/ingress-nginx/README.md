
## Ingress-nginx install on Bare metal clusters:

The Ingress-nginx controller is an open-source project that provides an Ingress controller for Kubernetes clusters. In Kubernetes, an Ingress is an API object that manages external access to services within a cluster, typically HTTP. The Ingress-nginx controller extends Kubernetes to provide powerful capabilities for routing external HTTP(S) traffic to services running within the cluster.


To install **ingress-nginx** on a bare metal Kubernetes cluster, you can follow these general steps:


### Nginx Ingress controller:

```
kubectl apply -f ingress-nginx-manifest.yaml
```



```
kubectl get ns


NAME              STATUS   AGE
ingress-nginx     Active   12s
```



```
kubectl get pods -n ingress-nginx


NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-kb5j2       0/1     Completed   0          38s
ingress-nginx-admission-patch-2twg6        0/1     Completed   0          38s
ingress-nginx-controller-6d4875f4d-72rlt   0/1     Running     0          40s
```



```
kubectl get svc -n ingress-nginx


NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.43.132.70    192.168.10.193   80:31072/TCP,443:32426/TCP   47s
ingress-nginx-controller-admission   ClusterIP      10.43.152.196   <none>           443/TCP                      47s
```



```
kubectl get secrets -n ingress-nginx


NAME                      TYPE     DATA   AGE
ingress-nginx-admission   Opaque   3      44s
```



```
kubectl get ingressClass -n nginx-ingress


NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       59s
```



```
kubectl get validatingwebhookconfigurations


NAME                            WEBHOOKS   AGE
ingress-nginx-admission         1          65s
metallb-webhook-configuration   6          60m
```





### Or, Using YAML Manifests:


**You can install Nginx Ingress controller using Kubernetes manifests directly:**

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml


or,

wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml


kubectl apply -f deploy.yaml
```


```
kubectl get ns

```


```
kubectl get pods -n ingress-nginx

NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-wdsb4        0/1     Completed   0          112s
ingress-nginx-admission-patch-w5mzd         0/1     Completed   0          112s
ingress-nginx-controller-5b7654867c-rbhb8   1/1     Running     0          113s
```


```
kubectl get svc -n ingress-nginx

NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller-admission   ClusterIP      10.43.221.71   <none>           443/TCP                      3m59s
ingress-nginx-controller             LoadBalancer   10.43.49.69    192.168.10.193   80:32624/TCP,443:32211/TCP   3m59s
```


```
kubectl get secrets -n ingress-nginx

NAME                      TYPE     DATA   AGE
ingress-nginx-admission   Opaque   3      4m17s
```


```
kubectl get ingressClass -n nginx-ingress

NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       4m45s
```


```
kubectl get validatingwebhookconfigurations

NAME                            WEBHOOKS   AGE
metallb-webhook-configuration   6          43h
ingress-nginx-admission         1          24m
```



---
---



## Configure Ingress Resources:

Now that ingress-nginx is installed, you can create Ingress resources to define how incoming traffic should be routed to your services.


### Host-Based:

Host-based ingress is a method of routing traffic to different services in a Kubernetes cluster based on the host header of the incoming HTTP request. This allows you to host multiple websites or services on the same cluster, each accessible via a different domain name.


To set up host-based ingress in Kubernetes, you typically follow these steps:

```
kubectl get svc


NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
webapp-wear-svc    NodePort    10.43.169.33   <none>        8080:30080/TCP   45m
webapp-video-svc   NodePort    10.43.67.255   <none>        8080:30081/TCP   44m
```



```
vim ingress-resources-host.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host-based
  #namespace:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /

spec:
  ingressClassName: nginx
  #ingressClassName: traefik
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
kubectl get ing
kubectl get ingress

NAME                 CLASS   HOSTS                          ADDRESS          PORTS   AGE
ingress-host-based   nginx   wear.idea.com,watch.idea.com   192.168.10.193   80      9m33s
```



#### Local DNS Entry:
```
192.168.10.193	wear.idea.com
192.168.10.193	watch.idea.com
```


_Check Service:_
```
curl wear.idea.com
curl watch.idea.com
```


---
---



### Path-Based:

Path-based ingress is a method of routing traffic to different services in a Kubernetes cluster based on the path of the incoming HTTP request. This allows you to host multiple services on the same domain or IP address, with each service accessible via a different path.

To set up path-based ingress in Kubernetes, you generally follow these steps:


```
kubectl get svc
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
webapp-wear-svc    NodePort    10.43.169.33   <none>        8080:30080/TCP   45m
webapp-video-svc   NodePort    10.43.67.255   <none>        8080:30081/TCP   44m

```


```
vim ingress-resources-path.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-path-based
  #namespace:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /

spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /wear
        pathType: Prefix
        backend:
          service:
           name: webapp-wear-svc  #service1
           port:
            number: 8080

      - path: /watch
        pathType: Prefix
        backend:
          service:
           name: webapp-video-svc  #service2
           port:
            number: 8080

```


```
kubectl apply -f ingress-resources-path.yaml
```



```
kubectl get ing
kubectl get ingress

NAME                 CLASS   HOSTS   ADDRESS          PORTS   AGE
ingress-path-based   nginx   *       192.168.10.193   80      116s
```


#### Local DNS Entry:
```
192.168.10.193	idea.com
```


_Check Service:_
```
curl idea.com/wear
curl idea.com/watch
```




### Links:
- [Ingress for Bare metal clusters](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal-clusters)



The Ingress-nginx controller is widely used in Kubernetes deployments to manage ingress traffic efficiently and securely. It's important to note that there are other Ingress controllers available for Kubernetes, but Ingress-nginx is one of the most popular and widely adopted due to its robust features and active community support.

Remember that the specific steps and configurations might vary depending on your bare metal environment and requirements. Always refer to the official documentation and best practices for Kubernetes and ingress-nginx deployments.




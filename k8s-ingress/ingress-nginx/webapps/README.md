## Application and Services Deploy:
Ensure you have a Kubernetes cluster set up and configured. This could be a local development cluster or self-managed clusters or a production-grade cluster (e.g.  managed Kubernetes services like Amazon EKS, Google Kubernetes Engine, Azure Kubernetes Service).

Deploying applications and services on Kubernetes involves several steps. Here's a basic overview of the process:

### Containerize Your Application:
Before deploying on Kubernetes, your application needs to be containerized. You can use Docker to create containers for your application components.


### Create Kubernetes Manifests:
Kubernetes uses YAML files called manifests to define the desired state of your application. These manifests describe the configuration of your application, including containers, pods, services, volumes, etc.


### Services:

A Kubernetes Service is a mechanism to expose applications both internally and externally.

Kubernetes allows the creation of these types of services:

- ClusterIP:  This is the default type for service in Kubernetes. This is just an address that can be used inside the cluster.
- Nodeport:  It exposes a port in each Node. When a NodePort is created, kube-proxy exposes a port in the range 30000-32767.
- LoadBalancer: Opens a port in every node like NodePort.
- ExternalName: It creates a single endpoint for all communications to that element.



### Create Pod: 
```
kubectl run webapp-wear --image kodekloud/ecommerce:apparels -o yaml --dry-run=client > webapp-wear.yaml

kubectl apply -f webapp-wear.yaml
```


```
kubectl get pod

NAME               READY   STATUS              RESTARTS   AGE
webapp-wear         1/1     Running             0          18m
```


#### Expose Pod: 

```
kubectl expose pod webapp-wear --name=webapp-wear-svc --type=NodePort --port=8080 --target-port=8080 -o yaml --dry-run=client > webapp-wear-svc.yaml
```


```
vim webapp-wear-svc.yaml

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: webapp-wear
  name: webapp-wear-svc
spec:
  ports:
  - port: 8080         #container service port/expose port
    protocol: TCP
    targetPort: 8080   #container port 8080
    #targetPort: 80    #container port 80 (if port: 80)
    nodePort: 30080    #manually add/assign nodePort
  selector:
    run: webapp-wear
  type: NodePort
```


```
kubectl apply -f webapp-wear-svc.yaml
```


```
kubectl get svc

NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
webapp-wear-svc   NodePort    10.43.69.23   <none>        8080:30080/TCP   112s
```


```
curl 192.168.10.190:30080
```


```
kubectl delete svc webapp-wear-svc
kubectl delete pod webapp-wear
```


### Create Deployment: 

```
kubectl create deployment  webapp-video --image kodekloud/ecommerce:video --replicas 2 -o yaml --dry-run=client > webapp-video.yaml
```


```
kubectl apply -f webapp-video.yaml
```


```
kubectl get pod

NAME                            READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
webapp-wear                     1/1     Running   0          91s   10.42.1.9    node01   <none>           <none>
webapp-video-7f469fbff8-f9glj   1/1     Running   0          67s   10.42.1.10   node01   <none>           <none>
webapp-video-7f469fbff8-qp588   1/1     Running   0          67s   10.42.2.10   node02   <none>           <none>
```


```
kubectl get deploy

NAME           READY   UP-TO-DATE   AVAILABLE   AGE
webapp-video   2/2     2            2           47s
```



#### Expose Deployment: 

```
kubectl expose deploy webapp-video --name=webapp-video-svc --type=NodePort --port=8080 --target-port=8080 -o yaml --dry-run=client > webapp-video-svc.yaml
```


```
vim webapp-video-svc.yaml

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: webapp-video
  name: webapp-video-svc
spec:
  ports:
  - port: 8080         #container service port/expose port
    protocol: TCP
    targetPort: 8080   #container port 8080
    #targetPort: 80    #container port 80 (if port: 80)
    nodePort: 30081    #manually add/assign nodePort
  selector:
    app: webapp-video
  type: NodePort
  #type: LoadBalancer
```


```
kubectl apply -f webapp-video-svc.yaml
```


```
kubectl get svc

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
webapp-wear-svc    NodePort    10.43.69.23    <none>        8080:30080/TCP   7m53s
webapp-video-svc   NodePort    10.43.165.55   <none>        8080:30081/TCP   40s
```


```
curl 192.168.10.190:30081
```


```
kubectl delete svc webapp-video-svc
kubectl delete deploy webapp-video 
```


**Note:** NodePort exposed port must be allow in the AWS security groups.


By following these steps, you can effectively deploy and manage your applications and services on Kubernetes.

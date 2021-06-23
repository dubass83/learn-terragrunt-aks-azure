# TRY terragrunt and Azure k8s
---
+ Run on terminal

```
az login
az ad sp create-for-rbac --skip-assignment
cd max/eu-central/prod/aks
export TF_VAR_appId=<paste azure application id>
export TF_VAR_password='<paste azure password>'
export AWS_PROFILE=s3-terraform-state
terragrant plan
terragrunt apply
az aks get-credentials --resource-group $(terragrunt output -raw resource_group_name) --name $(terragrunt output -raw kubernetes_cluster_name)
```

+ Check K8S cluster

```
kubectl get nodes -o wide
kubectl get pod --all-namespaces -o wide
kubectl get ns
kubectl run -it --rm pod1 --image=busybox --restart=Never -- sh
```

+ Clean

```
terragrunt destroy
```

+ Deploying all modules in Project

```
cd max/
terragrunt run-all plan --terragrunt-non-interactive
```

## Install Argo CD

+ Use Argo CD instractions from [getting_started](https://argoproj.github.io/argo-cd/getting_started/)
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
brew install argocd
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
argocd login localhost:8080

argocd app create guestbook \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path guestbook \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default \
    --port-forward-namespace argocd

argocd app get guestbook --port-forward-namespace argocd
argocd app sync guestbook --port-forward-namespace argocd

killall kubectl

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
argocd login argocd.dubass83.xyz
argocd app get guestbook
```
+ Add github auth to argo CD

`kubectl edit cm argocd-cm -n argocd`

Add to configmap
```yaml
data:
  url: https://argocd.example.com

  dex.config: |
    connectors:
      # GitHub example
      - type: github
        id: github
        name: GitHub
        config:
          clientID: aabbccddeeff00112233
          clientSecret: $dex.github.clientSecret
          orgs:
          - name: k8s-rs-test

```

``` 
kubectl -n argocd get secrets argocd-secret -o yaml
echo -n "<Paste GitHub clientSecret>" | base64

```
Edit secrets, add 'dex.github.clientSecret: YWZi<BASE64>3YTU1NTlhMjg1NWI4ZTE0Y2ZiMQ==' to data 

```
kubectl -n argocd edit secrets argocd-secret
```
+ Configure RBAC for Argo CD

```
kubectl -n argocd edit cm argocd-rbac-cm
```

Add to configmap

```yaml
data:
  policy.csv: |
    p, role:org-admin, applications, *, */*, allow
    p, role:org-admin, clusters, get, *, allow
    p, role:org-admin, repositories, get, *, allow
    p, role:org-admin, repositories, create, *, allow
    p, role:org-admin, repositories, update, *, allow
    p, role:org-admin, repositories, delete, *, allow

    g, k8s-rs-test:admin, role:org-admin
```

## Install Istio as Argo CD App
Need installed metrics-service for HPA in istod

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```
argocd app create istio-base \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path istio-base \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace istio-system

```

```
argocd app create istiod \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path istiod \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace istio-system

argocd app create istio-ingress \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path istio-ingress \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace istio-system
```

```
argocd app set istio-base --values values.yaml
argocd app set istiod --values values.yaml
argocd app set istio-ingress --values values.yaml
```

## Test Istio
```
kubectl create ns istio-app
kubectl get ns
kubectl label ns istio-app istio-injection=enabled
kubectl get ns --show-labels

argocd app create istio-sample-app \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path istio-sample-app \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace istio-app
```

curl http://istio-sample-app.dubass83.xyz/productpage

```
argocd app create istio-sleep-app \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path istio-sleep-app \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace istio-io-tcp-traffic-shifting
```
## Argo Rollouts

+ Install Argo Rollouts

```
app create argo-rollouts \                              
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path argo-rollouts \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace argo-rollouts
```

+ Create app blue-green deployment

```
argocd app create blue-green \
    --repo https://github.com/k8s-rs-test/argocd-example-apps.git \
    --path blue-green \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default
```
+ install cli tool for Argo Rollouts

`brew install argoproj/tap/kubectl-argo-rollouts`

+ show dashbord for Argo Rollouts

`kubectl argo rollouts dashboard`
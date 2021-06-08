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
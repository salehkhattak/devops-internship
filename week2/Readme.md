# Local Kubernetes Cluster using Terraform

## Prerequisites

- Terraform
- Docker
- Minikube
- kubectl

---

## Variables

| Variable | Description | Default |
|-----------|-------------|---------|
| cluster_name | Name of cluster | my-cluster |
| driver | Minikube driver | docker |
| cpus | CPU cores | 2 |
| memory | RAM (MB) | 4096 |
| kubernetes_version | Kubernetes version | stable |

---

## Deploy

```bash
terraform init
terraform apply
```

---

## Verify

```bash
kubectl cluster-info

kubectl get nodes

kubectl get pods -A
```

---

## Destroy

```bash
./scripts/destroy.sh
```

---

## Recreate

```bash
./scripts/create.sh
```

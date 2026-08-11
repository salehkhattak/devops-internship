# Week 4: Helm Chart Package & Kubernetes Deployment

## 📋 Overview

This project demonstrates packaging and deploying a Node.js microservice application using **Helm** (Kubernetes Package Manager).

The Helm chart packages all Kubernetes resources required to run the `parallax-app` application, including:
* Deployment with replica management, custom image, resource limits, and health probes
* NodePort Service for external network exposure
* ServiceAccount with auto-mounted API tokens
* Support for HorizontalPodAutoscaler (HPA) and Ingress configurations

---

## 📂 Project Structure

```text
week 4/
└── parallax-app/
    ├── Chart.yaml
    ├── values.yaml
    ├── .helmignore
    ├── charts/
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml
        ├── hpa.yaml
        ├── ingress.yaml
        ├── NOTES.txt
        ├── service.yaml
        ├── serviceaccount.yaml
        └── tests/
            └── test-connection.yaml
```

---

## 🏗️ Chart Configuration (`values.yaml`)

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| `replicaCount` | `2` | Number of pod replicas |
| `image.repository` | `salehktk005/simple-node-app` | Docker image repository |
| `image.tag` | `"v1"` | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull strategy |
| `service.type` | `NodePort` | Kubernetes service type |
| `service.port` | `3000` | Exposed service port |
| `resources.requests.cpu` | `250m` | Requested CPU allocation |
| `resources.requests.memory` | `256Mi` | Requested Memory allocation |
| `resources.limits.cpu` | `500m` | Maximum CPU limit |
| `resources.limits.memory` | `512Mi` | Maximum Memory limit |
| `livenessProbe.httpGet.path` | `/health` | Liveness health check path |
| `livenessProbe.httpGet.port` | `3000` | Liveness health check port |
| `readinessProbe.httpGet.path` | `/health` | Readiness check path |
| `readinessProbe.httpGet.port` | `3000` | Readiness check port |

---

## 🚀 Helm Usage & Deployment

### 1. Lint Chart

Verify that the chart is free of syntax and structural errors:

```bash
helm lint ./parallax-app
```

### 2. Render Templates (Dry Run)

Preview the generated Kubernetes manifests without deploying to a cluster:

```bash
helm template parallax-release ./parallax-app
```

### 3. Deploy Chart

Install the Helm release into your Kubernetes cluster:

```bash
helm install parallax-release ./parallax-app -n parallax --create-namespace
```

### 4. Upgrade Release

Apply updated configurations:

```bash
helm upgrade parallax-release ./parallax-app -n parallax
```

### 5. Uninstall Release

Clean up deployed resources:

```bash
helm uninstall parallax-release -n parallax
```

---

## ⚠️ Issues Identified & Resolution

### Root Cause
`helm lint` previously failed with the error:
`Error unable to check Chart.yaml file in chart... Chart.yaml file is missing`

The `Chart.yaml` file was incorrectly placed inside the subchart directory (`charts/Chart.yaml`) instead of the chart's root directory (`parallax-app/Chart.yaml`).

### Resolution
1. Created the root `Chart.yaml` with chart metadata (`apiVersion: v2`, `name: parallax-app`, `version: 0.1.0`, `appVersion: "1.16.0"`).
2. Removed the misplaced `charts/Chart.yaml`.
3. Verified chart syntax and rendering with `helm lint` and `helm template`.

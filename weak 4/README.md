# Week 4: Custom Helm Chart Package & Multi-Service Kubernetes Deployment

## 📋 Overview

This project demonstrates packaging and deploying a multi-service Node.js application using **Helm** (Kubernetes Package Manager).

The Helm chart abstracts and manages all Kubernetes resources required for both **Frontend** and **Backend** microservices in the `parallax-app` architecture:
* **Frontend Microservice Deployment & NodePort Service** (Port 3000, 2 replicas)
* **Backend Microservice Deployment & ClusterIP Service** (Port 5000, 2 replicas)
* **Shared ConfigMap Resource** (`app-config` for `APP_ENV` and `BACKEND_URL`)
* **Shared Secret Resource** (`app-secret` for `API_KEY`)
* **ServiceAccount with API credentials**
* **Support for HorizontalPodAutoscaler (HPA) and Ingress configurations**

---

## 📂 Project Structure

```text
weak 4/
└── parallax-app/
    ├── Chart.yaml
    ├── values.yaml
    ├── .helmignore
    ├── charts/
    └── templates/
        ├── _helpers.tpl
        ├── frontend-deployment.yaml
        ├── frontend-service.yaml
        ├── backend-deployment.yaml
        ├── backend-service.yaml
        ├── configmap.yaml
        ├── secret.yaml
        ├── hpa.yaml
        ├── ingress.yaml
        ├── serviceaccount.yaml
        └── tests/
            └── test-connection.yaml
```

---

## 🏗️ Chart Configuration (`values.yaml`)

### Global & Shared Resources

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| `serviceAccount.create` | `true` | Create dedicated ServiceAccount |
| `configMap.enabled` | `true` | Generate shared ConfigMap resource |
| `configMap.name` | `"app-config"` | ConfigMap resource name |
| `secret.enabled` | `true` | Generate shared Secret resource |
| `secret.name` | `"app-secret"` | Secret resource name |

### Frontend Microservice (`frontend`)

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| `frontend.enabled` | `true` | Enable Frontend microservice deployment |
| `frontend.replicaCount` | `2` | Number of frontend pod replicas |
| `frontend.image.repository` | `salehktk005/simple-node-app` | Frontend Docker image repository |
| `frontend.image.tag` | `"v1"` | Frontend image tag |
| `frontend.containerPort` | `3000` | Port container listens on |
| `frontend.service.type` | `NodePort` | Kubernetes service type for external access |
| `frontend.service.port` | `3000` | Exposed service port |
| `frontend.env.PORT` | `"3000"` | Container PORT environment variable |
| `frontend.env.SERVICE_NAME` | `"frontend"` | Container SERVICE_NAME environment variable |
| `frontend.resources.requests.cpu` | `250m` | Requested CPU allocation |
| `frontend.resources.requests.memory` | `256Mi` | Requested Memory allocation |
| `frontend.resources.limits.cpu` | `500m` | Maximum CPU limit |
| `frontend.resources.limits.memory` | `512Mi` | Maximum Memory limit |
| `frontend.livenessProbe.httpGet.path` | `/health` | Liveness probe endpoint |
| `frontend.readinessProbe.httpGet.path` | `/health` | Readiness probe endpoint |

### Backend Microservice (`backend`)

| Parameter | Default Value | Description |
| --------- | ------------- | ----------- |
| `backend.enabled` | `true` | Enable Backend microservice deployment |
| `backend.replicaCount` | `2` | Number of backend pod replicas |
| `backend.image.repository` | `salehktk005/simple-node-app` | Backend Docker image repository |
| `backend.image.tag` | `"v1"` | Backend image tag |
| `backend.containerPort` | `5000` | Port container listens on |
| `backend.service.type` | `ClusterIP` | Kubernetes service type for internal access |
| `backend.service.port` | `5000` | Internal exposed service port |
| `backend.env.PORT` | `"5000"` | Container PORT environment variable |
| `backend.env.SERVICE_NAME` | `"backend"` | Container SERVICE_NAME environment variable |
| `backend.resources.requests.cpu` | `250m` | Requested CPU allocation |
| `backend.resources.requests.memory` | `256Mi` | Requested Memory allocation |
| `backend.resources.limits.cpu` | `500m` | Maximum CPU limit |
| `backend.resources.limits.memory` | `512Mi` | Maximum Memory limit |
| `backend.livenessProbe.httpGet.path` | `/health` | Liveness probe endpoint |
| `backend.readinessProbe.httpGet.path` | `/health` | Readiness probe endpoint |

---

## 🚀 Helm Usage & Deployment

### 1. Lint Chart

Verify that the chart templates and values are structurally sound:

```bash
helm lint ./parallax-app
```

### 2. Render Templates (Dry Run)

Preview all generated Kubernetes manifests for both frontend and backend microservices:

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

### 5. Test Release Connection

Run Helm test hook to verify service health:

```bash
helm test parallax-release -n parallax
```

### 6. Uninstall Release

Clean up deployed resources:

```bash
helm uninstall parallax-release -n parallax
```

---

## ⚠️ Issues Identified & Resolution

### Refactoring Default Boilerplate to Custom Microservices Chart

1. **Problem**: The original chart used the default single-deployment boilerplate (`deployment.yaml` and `service.yaml`) from `helm create`, which did not abstract separate frontend and backend microservices.
2. **Resolution**:
   * Designed concrete dedicated templates for `frontend-deployment.yaml`, `frontend-service.yaml`, `backend-deployment.yaml`, and `backend-service.yaml`.
   * Added `configmap.yaml` and `secret.yaml` templates driven by `values.yaml`.
   * Added dedicated helper functions in `_helpers.tpl` for labels and selectors for both microservices.
   * Updated `hpa.yaml`, `ingress.yaml`, `NOTES.txt`, and test hooks to handle multi-service deployments seamlessly.

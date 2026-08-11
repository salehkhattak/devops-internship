# 🌐 Frontend Microservice Manifests

## 📋 Overview
This directory contains the raw Kubernetes manifests (`deployment.yaml` and `service.yaml`) for the **Frontend** microservice in the `parallax` namespace.

---

## 📄 File Manifests

### 1. `deployment.yaml`
Deploys 2 replicas of the frontend microservice.
- **Image**: `salehktk005/simple-node-app:v1`
- **Port**: `3000`
- **Environment Variables**:
  - `PORT`: `"3000"`
  - `SERVICE_NAME`: `"frontend"`
  - Injected from `app-config` ConfigMap (`APP_ENV`, `BACKEND_URL`)
- **Resource Requests & Limits**:
  - Requests: CPU `250m`, Memory `256Mi`
  - Limits: CPU `500m`, Memory `512Mi`
- **Health Probes**:
  - **Liveness Probe**: HTTP GET `/health` on port 3000 (Initial Delay: 10s)
  - **Readiness Probe**: HTTP GET `/health` on port 3000 (Initial Delay: 5s)

### 2. `service.yaml`
Exposes the Frontend Deployment outside the cluster using a `NodePort` service on port `3000`.

---

## 🛠️ Usage Instructions

### Apply Manifests
```bash
kubectl apply -f service.yaml -n parallax
kubectl apply -f deployment.yaml -n parallax
```

### Verify Deployment
```bash
kubectl get pods -l app=frontend -n parallax
kubectl get svc frontend-service -n parallax
```

### Access Frontend Service via Minikube
```bash
minikube service frontend-service -n parallax
```

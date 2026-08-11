# ⚙️ Backend Microservice Manifests

## 📋 Overview
This directory contains the raw Kubernetes manifests (`deployment.yaml` and `service.yaml`) for the **Backend** microservice in the `parallax` namespace.

---

## 📄 File Manifests

### 1. `deployment.yaml`
Deploys 2 replicas of the backend microservice.
- **Image**: `salehktk005/simple-node-app:v1`
- **Port**: `5000`
- **Environment Variables**:
  - `PORT`: `"5000"`
  - `SERVICE_NAME`: `"backend"`
  - Injected from `app-config` ConfigMap (`APP_ENV`, `BACKEND_URL`)
  - Injected from `app-secret` Secret (`API_KEY`)
- **Resource Requests & Limits**:
  - Requests: CPU `250m`, Memory `256Mi`
  - Limits: CPU `500m`, Memory `512Mi`
- **Health Probes**:
  - **Liveness Probe**: HTTP GET `/health` on port 5000 (Initial Delay: 10s, Period: 10s)
  - **Readiness Probe**: HTTP GET `/health` on port 5000 (Initial Delay: 5s, Period: 5s)

### 2. `service.yaml`
Exposes the Backend Deployment internally to other pods in the cluster using a `ClusterIP` service on port `5000`.

---

## 🛠️ Usage Instructions

### Apply Manifests
```bash
kubectl apply -f service.yaml -n parallax
kubectl apply -f deployment.yaml -n parallax
```

### Verify Deployment
```bash
kubectl get pods -l app=backend -n parallax
kubectl get svc backend-service -n parallax
```

### Test Internal Communication from a Pod
```bash

kubectl exec -n parallax -it frontend-7d9dc4dc6-wrbzs -- curl http://backend-service:5000/health
```

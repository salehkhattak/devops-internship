# Week 3: Raw Kubernetes Manifests & Microservice Deployment

## 📋 Overview

This project demonstrates deploying a multi-service application to a Kubernetes cluster using **raw Kubernetes YAML manifests**. The application consists of two microservices (Frontend and Backend) deployed on a local **Minikube** cluster.

The project covers fundamental Kubernetes concepts including:

* Namespaces for workload isolation
* Deployments and ReplicaSets
* ClusterIP and NodePort Services
* ConfigMaps for configuration management
* Secrets for sensitive information
* Resource Requests & Limits
* Liveness and Readiness Probes
* Internal service-to-service communication

---

# 📂 Project Structure

```text
week3/
├── app/
│   ├── app.js
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── package.json
│   └── README.md
│
├── frontend/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── README.md
│
├── backend/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── README.md
│
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
└── README.md
```

---

# 🎯 Objectives

* Deploy frontend and backend microservices using raw Kubernetes manifests.
* Configure Deployments, Services, ConfigMaps, and Secrets.
* Enable communication between microservices inside the Kubernetes cluster.
* Configure CPU and Memory Requests/Limits.
* Configure Liveness and Readiness Probes.
* Verify successful deployment using kubectl.

---

# 🏗️ Kubernetes Resources

## Namespace

Creates an isolated namespace named **parallax** for all application resources.

```yaml
kind: Namespace
metadata:
  name: parallax
```

---

## ConfigMap

Stores non-sensitive configuration values.

| Key         | Value                       |
| ----------- | --------------------------- |
| APP_ENV     | production                  |
| BACKEND_URL | http://backend-service:5000 |

---

## Secret

Stores sensitive application data.

| Key     | Value       |
| ------- | ----------- |
| API_KEY | parallax123 |

---

# 🚀 Microservices

## Frontend

* Deployment
* NodePort Service
* 2 Replicas
* Port 3000

Features

* Resource Requests & Limits
* Liveness Probe
* Readiness Probe
* Reads configuration from ConfigMap

---

## Backend

* Deployment
* ClusterIP Service
* 2 Replicas
* Port 5000

Features

* Resource Requests & Limits
* Liveness Probe
* Readiness Probe
* Reads configuration from ConfigMap
* Reads API Key from Secret

---

# 📊 Deployment Configuration

| Resource        | Frontend | Backend   |
| --------------- | -------- | --------- |
| Replicas        | 2        | 2         |
| Container Port  | 3000     | 5000      |
| Service Type    | NodePort | ClusterIP |
| Requests CPU    | 250m     | 250m      |
| Limits CPU      | 500m     | 500m      |
| Requests Memory | 256Mi    | 256Mi     |
| Limits Memory   | 512Mi    | 512Mi     |
| Liveness Probe  | /health  | /health   |
| Readiness Probe | /health  | /health   |

---

# 🛠️ Prerequisites

Before deployment ensure the following are installed:

* Docker
* Minikube
* kubectl

Start Minikube

```bash
minikube start
```

---

# 📦 Build the Docker Image

Build the application image:

```bash
minikube image build -t salehktk005/simple-node-app:v1 ./app
```

Alternatively:

```bash
docker build -t salehktk005/simple-node-app:v1 ./app

docker push salehktk005/simple-node-app:v1
```

---

# 🚀 Deployment Steps

## 1. Create Namespace

```bash
kubectl apply -f namespace.yaml
```

## 2. Create ConfigMap

```bash
kubectl apply -f configmap.yaml
```

## 3. Create Secret

```bash
kubectl apply -f secret.yaml
```

## 4. Deploy Backend

```bash
kubectl apply -f backend/service.yaml

kubectl apply -f backend/deployment.yaml
```

## 5. Deploy Frontend

```bash
kubectl apply -f frontend/service.yaml

kubectl apply -f frontend/deployment.yaml
```

---

# ✅ Verification

Check all resources

```bash
kubectl get all -n parallax
```

Check Pods

```bash
kubectl get pods -n parallax
```

Check Services

```bash
kubectl get svc -n parallax
```

Check Deployments

```bash
kubectl get deployments -n parallax
```

---

# 🔗 Internal Service Communication

Enter one of the frontend pods.

```bash
kubectl exec -it -n parallax <frontend-pod-name> -- sh
```

Test backend connectivity.

```bash
curl http://backend-service:5000/health
```

Expected response

```json
{
  "status":"UP",
  "service":"backend",
  "port":"5000"
}
```

Test another backend endpoint

```bash
curl http://backend-service:5000/api/info
```

Successful responses confirm that Kubernetes DNS-based service discovery is functioning correctly.

---

# 🩺 Health Checks

Both Deployments implement:

* Liveness Probe
* Readiness Probe

The probes continuously monitor the `/health` endpoint to ensure:

* Unhealthy containers are automatically restarted.
* Traffic is routed only to healthy pods.

---

# 💻 Resource Management

Each Deployment defines resource requests and limits.

**Requests**

* CPU: 250m
* Memory: 256Mi

**Limits**

* CPU: 500m
* Memory: 512Mi

This prevents resource starvation while ensuring stable scheduling.

---

# 🧹 Cleanup

Delete all deployed resources.

```bash
kubectl delete namespace parallax
```

---

# ⚠️ Challenges Faced & Resolution

During deployment, Kubernetes initially failed to start the application pods because the container image referenced in the Deployment (`salehktk005/simple-node-app:v1`) was not available.

As a result, the pods entered the following states:

```text
ErrImagePull
ImagePullBackOff
```

## Root Cause

The Deployment manifest referenced a Docker image that had not yet been built or published. Since Kubernetes could not locate the image, it was unable to create the containers.

## Resolution

To resolve this issue, the following steps were performed:

1. Created a lightweight Node.js application inside the `app/` directory.
2. Added the required `/health` and `/info` endpoints for Kubernetes health checks.
3. Containerized the application using a Dockerfile.
4. Built the Docker image locally.

```bash
docker build -t salehktk005/simple-node-app:v1 ./app
```

5. Uploaded the image to Docker Hub.

```bash
docker push salehktk005/simple-node-app:v1
```

6. Updated the Kubernetes Deployment manifests to use the published image.

```yaml
image: salehktk005/simple-node-app:v1
```

7. Reapplied the Kubernetes manifests.

```bash
kubectl apply -f backend/
kubectl apply -f frontend/
```

After the image became available, Kubernetes successfully pulled the container image, all pods entered the **Running** state, and the frontend and backend services communicated successfully inside the cluster.

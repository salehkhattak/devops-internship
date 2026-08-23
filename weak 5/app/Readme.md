# 🚀 Parallax Microservice Application (Istio mTLS Enabled)

## 📋 Context & Purpose
This Node.js application serves as the core containerized microservice image (`salehktk005/simple-node-app:v1` / `parallax-microservice`) for the **Week 5 Istio Service Mesh & Strict mTLS Integration** task.

It is designed to run seamlessly as both **Frontend** and **Backend** microservice instances within Kubernetes behind Istio Envoy sidecars.

---

## ✨ Application Features & Customizations (Week 5)

- **Istio mTLS Telemetry & Header Inspection**: Automatically inspects incoming Envoy sidecar headers (`x-forwarded-client-cert`, `x-b3-traceid`, `x-request-id`) to verify active Mutual TLS encryption.
- **Inter-Service Communication Endpoint (`/api/backend-status`)**: Enables frontend pods to perform an internal HTTP GET request to the backend microservice (`BACKEND_URL`), validating active Envoy proxying.
- **Health Check Endpoint (`/health`)**: Dedicated HTTP 200 route returning JSON status for Kubernetes liveness & readiness probes.
- **API Info Endpoint (`/api/info`)**: Returns runtime service name, environment, configuration status, and Istio mTLS identity metrics.
- **Modern Glassmorphic Web Interface (`/`)**: Dark mode dashboard built with HSL color palettes, responsive cards, and live inter-service status tester.

---

## 📂 Project Structure
```text
app/
├── app.js               # Node.js server with Istio mTLS inspection & backend status fetcher
├── dockerfile           # Lightweight Node.js Dockerfile
├── docker-compose.yml   # Local Docker Compose setup
├── package.json         # Package definition
└── Readme.md            # Application documentation
```

---

## 🔌 API Endpoints Summary

| Endpoint | Method | Response | Description |
| :--- | :--- | :--- | :--- |
| `/` | `GET` | HTML Web UI | Interactive dashboard with live mTLS connection tester |
| `/health` | `GET` | JSON | Liveness & readiness probe endpoint (`status: UP`) |
| `/api/info` | `GET` | JSON | Microservice info & Istio mTLS certificate headers |
| `/api/backend-status` | `GET` | JSON | Performs inter-service call to `BACKEND_URL` over mTLS |

---

## 🛠️ Build and Deployment Instructions

### 1. Build Docker Image
```bash
docker build -t salehktk005/simple-node-app:v1 .
```

### 2. Run Locally with Docker
```bash
docker run -d -p 3000:3000 -e PORT=3000 -e SERVICE_NAME=frontend salehktk005/simple-node-app:v1
```

### 3. Load Image into Minikube / Kubernetes Cluster
```bash
minikube image build -t salehktk005/simple-node-app:v1 .
# OR
minikube image load salehktk005/simple-node-app:v1
```

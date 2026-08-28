# Week 6: Kong API Gateway Integration

This folder contains the implementation for Week 6 of the DevOps internship. The primary objective is to install and configure Kong as an API Gateway, taking the microservices deployed in Week 5 and exposing them securely.

## Objectives Achieved
- **Kong Ingress Controller**: Deployed Kong as the single ingress point for the Kubernetes cluster.
- **Microservices Routing**: Configured the frontend and backend microservices to route through Kong using Ingress and Service annotations.
- **Rate Limiting**: Applied a `rate-limiting` plugin to the frontend, restricted to 5 requests per minute.
- **API Key Authentication**: Secured the backend (`/api`) route with the `key-auth` plugin, requiring consumers to pass a valid `apikey` header.
- **Automated Testing**: Created PowerShell scripts to automatically verify the rate limiting and authentication functionality.

## Directory Structure
- `parallax-app/`: The Helm chart for our frontend and backend microservices, now updated to utilize Kong ingress and plugin annotations.
- `kong/`: Kubernetes manifests for Kong custom resources:
  - `rate-limit-plugin.yaml`: Limits requests to 5/minute.
  - `key-auth-plugin.yaml`: Enforces API key verification.
  - `consumer.yaml`: Provisions a KongConsumer and a Kubernetes Secret containing a test API key (`secret123`).
- `scripts/`: Automation scripts for deployment and verification.

## Getting Started

### Prerequisites
- A running Kubernetes cluster (e.g., Minikube, Docker Desktop).
- Helm and `kubectl` installed and configured.

### 1. Install Kong API Gateway
Run the following script to add the Kong Helm repository and install the ingress controller in the `kong` namespace:
```powershell
.\scripts\install-kong.ps1
```

### 2. Deploy Application & Plugins
Deploy the frontend and backend microservices, alongside the Kong plugins and consumer secrets:
```powershell
.\scripts\deploy-app.ps1
```

### 3. Verify Rate Limiting
Run the rate limiting test script. It will send 10 rapid requests to the frontend service. You should observe HTTP `200 OK` for the first 5 requests, followed by HTTP `429 Too Many Requests` as the rate limiter kicks in:
```powershell
.\scripts\test-rate-limiting.ps1
```

### 4. Verify API Key Authentication
Run the authentication test script. It will attempt to access the backend API twice:
1. Without an API key (Expecting HTTP `401 Unauthorized`)
2. With the valid API key `secret123` (Expecting HTTP `200 OK`)
```powershell
.\scripts\test-key-auth.ps1
```

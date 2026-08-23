#!/usr/bin/env bash
# Week 5: Application Deployment & Strict mTLS Configuration Script

set -e

echo "=================================================================="
echo "      DEPLOYING APPLICATION & ENFORCING STRICT mTLS               "
echo "=================================================================="

NAMESPACE="parallax"

# 1. Lint chart
echo "[1/4] Linting Helm Chart..."
helm lint ./weak\ 5/parallax-app

# 2. Deploy Application via Helm
echo "[2/4] Deploying Helm release parallax-release into namespace ${NAMESPACE}..."
helm upgrade --install parallax-release ./weak\ 5/parallax-app -n ${NAMESPACE} --create-namespace

# 3. Apply Strict mTLS Policy
echo "[3/4] Applying Strict mTLS PeerAuthentication..."
kubectl apply -f weak\ 5/istio/peer-authentication.yaml

# 4. Deploy un-injected test pod for verification
echo "[4/4] Deploying un-injected test pod in legacy namespace..."
kubectl apply -f weak\ 5/verification/uninjected-pod.yaml

echo ""
echo "Waiting for all pods in ${NAMESPACE} to reach Ready state..."
kubectl rollout status deployment/parallax-release-parallax-app-frontend -n ${NAMESPACE}
kubectl rollout status deployment/parallax-release-parallax-app-backend -n ${NAMESPACE}

echo ""
echo "=================================================================="
echo "         APPLICATION DEPLOYED & STRICT mTLS ENFORCED             "
echo "=================================================================="

#!/usr/bin/env bash
# Week 5: Istio Helm Installation Script

set -e

echo "=================================================================="
echo "          INSTALLING ISTIO SERVICE MESH VIA HELM                  "
echo "=================================================================="

# 1. Add Istio Helm repository
echo "[1/4] Adding Istio Helm Repository..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# 2. Create istio-system namespace
echo "[2/4] Creating istio-system namespace..."
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

# 3. Install Istio Base (CRDs)
echo "[3/4] Installing Istio Base CRDs..."
helm upgrade --install istio-base istio/base -n istio-system --wait

# 4. Install Istiod Control Plane
echo "[4/4] Installing Istiod Control Plane..."
helm upgrade --install istiod istio/istiod -n istio-system --wait

echo ""
echo "Enabling automatic sidecar injection for namespace 'parallax'..."
kubectl create namespace parallax --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace parallax istio-injection=enabled --overwrite

echo ""
echo "=================================================================="
echo "         ISTIO SERVICE MESH INSTALLED SUCCESSFULLY               "
echo "=================================================================="

#!/usr/bin/env bash
set -euo pipefail
ARGOCD_VERSION="v3.5.4"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
kubectl -n argocd rollout status deployment/argocd-server --timeout=180s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=180s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=180s
echo "ArgoCD is installed in namespace argocd."
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v helm >/dev/null || { echo "helm is required to render weak 6/parallax-app." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required to validate the ArgoCD resources." >&2; exit 1; }
helm template parallax-release "$ROOT/weak 6/parallax-app" >/dev/null
kubectl apply --dry-run=client --validate=false -f "$ROOT/weak 8/argocd/application.yaml" >/dev/null
kubectl apply --dry-run=client --validate=false -f "$ROOT/weak 8/argocd/notification-configmap.yaml" >/dev/null
echo "Week 8 validation passed."

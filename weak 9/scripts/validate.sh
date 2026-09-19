#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEEK="$ROOT/weak 9"

command -v helm >/dev/null 2>&1 || { echo "Error: helm is required for validation. Please install Helm 3." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "Error: kubectl is required for validation. Please install kubectl." >&2; exit 1; }

echo "Validating Helm values..."
helm template kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --values "$WEEK/monitoring/values.yaml" >/dev/null

echo "Validating Kubernetes manifests..."
for file in app-podmonitor.yaml kong-servicemonitor.yaml kong-prometheus-plugin.yaml grafana-dashboard.yaml; do
  kubectl apply --dry-run=client --validate=false -f "$WEEK/monitoring/$file" >/dev/null
done

echo "Week 9 monitoring manifests validation passed successfully."
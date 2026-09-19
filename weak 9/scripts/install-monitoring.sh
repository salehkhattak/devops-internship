#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEEK="$ROOT/weak 9"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values "$WEEK/monitoring/values.yaml" --wait --timeout 10m
kubectl apply -f "$WEEK/monitoring/app-podmonitor.yaml"
kubectl apply -f "$WEEK/monitoring/kong-servicemonitor.yaml"
kubectl apply -f "$WEEK/monitoring/kong-prometheus-plugin.yaml"
kubectl apply -f "$WEEK/monitoring/grafana-dashboard.yaml"
kubectl -n monitoring rollout status deployment/kube-prometheus-stack-grafana --timeout=180s
kubectl -n monitoring rollout status statefulset/prometheus-kube-prometheus-stack-prometheus --timeout=180s
echo "Prometheus, Grafana, app scraping, Kong scraping, and dashboard provisioning are ready."
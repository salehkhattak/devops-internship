$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$week = Join-Path $root "weak 9"
$chartVersion = "92.2.0"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version $chartVersion --namespace monitoring --create-namespace --values (Join-Path $week "monitoring\values.yaml") --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { throw "kube-prometheus-stack $chartVersion installation failed." }
kubectl apply -f (Join-Path $week "monitoring\app-podmonitor.yaml")
kubectl apply -f (Join-Path $week "monitoring\kong-servicemonitor.yaml")
kubectl apply -f (Join-Path $week "monitoring\kong-prometheus-plugin.yaml")
kubectl apply -f (Join-Path $week "monitoring\grafana-dashboard.yaml")
kubectl -n monitoring rollout status deployment/kube-prometheus-stack-grafana --timeout=180s
kubectl -n monitoring rollout status statefulset/prometheus-kube-prometheus-stack-prometheus --timeout=180s
Write-Host "Prometheus, Grafana, app scraping, Kong scraping, and dashboard provisioning are ready."
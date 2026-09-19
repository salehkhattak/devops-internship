$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$week = Join-Path $root "weak 9"

if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    throw "helm is required for validation. Please install Helm 3 and re-run."
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required for validation. Please install kubectl and re-run."
}

Write-Host "Validating Helm values..."
helm template kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --values (Join-Path $week "monitoring\values.yaml") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Prometheus stack Helm rendering failed." }

Write-Host "Validating Kubernetes manifests..."
$manifests = @(
    "app-podmonitor.yaml",
    "kong-servicemonitor.yaml",
    "kong-prometheus-plugin.yaml",
    "grafana-dashboard.yaml"
)

foreach ($file in $manifests) {
    kubectl apply --dry-run=client --validate=false -f (Join-Path $week "monitoring\$file") | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Validation failed for $file." }
}

Write-Host "Week 9 monitoring manifests validation passed successfully."
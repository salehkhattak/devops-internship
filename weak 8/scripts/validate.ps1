$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
	throw "helm is required to render weak 6/parallax-app. Install Helm and rerun validation."
}
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
	throw "kubectl is required to validate the ArgoCD resources."
}
helm template parallax-release (Join-Path $root "weak 6\parallax-app") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Helm chart rendering failed." }
kubectl apply --dry-run=client --validate=false -f (Join-Path $root "weak 8\argocd\application.yaml") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "ArgoCD Application validation failed." }
kubectl apply --dry-run=client --validate=false -f (Join-Path $root "weak 8\argocd\notification-configmap.yaml") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Notification ConfigMap validation failed." }
Write-Host "Week 8 validation passed."
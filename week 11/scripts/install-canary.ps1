$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$week5 = Join-Path $root "weak 5"
$week10 = Join-Path $root "week 10"
$week11 = Join-Path $root "week 11"

& (Join-Path $week10 "scripts\install-alerting.ps1")
if ($LASTEXITCODE -ne 0) { throw "Week 10 Alertmanager and Prometheus installation failed." }

kubectl apply -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
if ($LASTEXITCODE -ne 0) { throw "Argo Rollouts controller installation failed." }
kubectl -n argo-rollouts rollout status deployment/argo-rollouts --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "Argo Rollouts controller did not become ready." }

helm upgrade --install parallax-release (Join-Path $week5 "parallax-app") `
    --namespace parallax --create-namespace --set frontend.enabled=false `
    --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { throw "The Parallax Helm release could not disable its frontend Deployment." }

kubectl apply -f (Join-Path $week11 "monitoring\canary-analysis.yaml")
if ($LASTEXITCODE -ne 0) { throw "The canary Prometheus AnalysisTemplate could not be applied." }
kubectl apply -f (Join-Path $week11 "rollout\canary.yaml")
if ($LASTEXITCODE -ne 0) { throw "The Istio canary resources could not be applied." }
kubectl -n parallax rollout status rollout/parallax-frontend --timeout=300s
if ($LASTEXITCODE -ne 0) { throw "The initial frontend Rollout did not become healthy." }

Write-Host "Week 11 metric-gated frontend canary is ready."
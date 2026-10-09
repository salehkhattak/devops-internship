$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$week9 = Join-Path $root "weak 9"
$week10 = Join-Path $root "week 10"
$chartVersion = "92.2.0"

& (Join-Path $week9 "scripts\install-monitoring.ps1")
if ($LASTEXITCODE -ne 0) { throw "Week 9 monitoring installation failed." }

kubectl apply -f (Join-Path $week10 "monitoring\alertmanager-webhook.yaml")
if ($LASTEXITCODE -ne 0) { throw "Mock webhook deployment failed." }
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
    --version $chartVersion `
    --namespace monitoring `
    --values (Join-Path $week9 "monitoring\values.yaml") `
    --values (Join-Path $week10 "monitoring\alertmanager-values.yaml") `
    --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { throw "Alertmanager Helm configuration failed." }

kubectl apply -f (Join-Path $week10 "monitoring\prometheus-rules.yaml")
if ($LASTEXITCODE -ne 0) { throw "Prometheus alert rules could not be applied." }
kubectl -n monitoring rollout status deployment/alertmanager-webhook --timeout=180s
kubectl -n monitoring rollout status statefulset/alertmanager-kube-prometheus-stack-alertmanager --timeout=180s
Write-Host "Week 10 alert rules and the Alertmanager mock webhook are ready."
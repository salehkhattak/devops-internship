# Week 5: Istio Helm Installation Script (PowerShell)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "          INSTALLING ISTIO SERVICE MESH VIA HELM                  " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "`n[1/4] Adding Istio Helm Repository..." -ForegroundColor Yellow
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

Write-Host "`n[2/4] Creating istio-system namespace..." -ForegroundColor Yellow
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -

Write-Host "`n[3/4] Installing Istio Base CRDs..." -ForegroundColor Yellow
helm upgrade --install istio-base istio/base -n istio-system --wait

Write-Host "`n[4/4] Installing Istiod Control Plane..." -ForegroundColor Yellow
helm upgrade --install istiod istio/istiod -n istio-system --wait

Write-Host "`nEnabling automatic sidecar injection for namespace 'parallax'..." -ForegroundColor Yellow
kubectl create namespace parallax --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace parallax istio-injection=enabled --overwrite

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "         ISTIO SERVICE MESH INSTALLED SUCCESSFULLY               " -ForegroundColor Cyan

# Week 5: Application Deployment & Strict mTLS Configuration Script (PowerShell)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "      DEPLOYING APPLICATION & ENFORCING STRICT mTLS               " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$Namespace = "parallax"

Write-Host "`n[1/4] Linting Helm Chart..." -ForegroundColor Yellow
helm lint "weak 5/parallax-app"

Write-Host "`n[2/4] Deploying Helm release parallax-release into namespace $Namespace..." -ForegroundColor Yellow
helm upgrade --install parallax-release "weak 5/parallax-app" -n $Namespace --create-namespace

Write-Host "`n[3/4] Applying Strict mTLS PeerAuthentication..." -ForegroundColor Yellow
kubectl apply -f "weak 5/istio/peer-authentication.yaml"

Write-Host "`n[4/4] Deploying un-injected test pod in legacy namespace..." -ForegroundColor Yellow
kubectl apply -f "weak 5/verification/uninjected-pod.yaml"

Write-Host "`nWaiting for all deployments in $Namespace to reach Ready state..." -ForegroundColor Yellow
kubectl rollout status deployment/parallax-release-parallax-app-frontend -n $Namespace
kubectl rollout status deployment/parallax-release-parallax-app-backend -n $Namespace

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "         APPLICATION DEPLOYED & STRICT mTLS ENFORCED             " -ForegroundColor Cyan

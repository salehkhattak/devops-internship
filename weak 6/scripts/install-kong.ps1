# install-kong.ps1
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                INSTALLING KONG API GATEWAY                       " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# Add Kong Helm repo
helm repo add kong https://charts.konghq.com
helm repo update

# Install Kong in the 'kong' namespace
Write-Host "`nInstalling Kong Ingress Controller..." -ForegroundColor Yellow
helm upgrade --install kong kong/ingress -n kong --create-namespace

Write-Host "`nWaiting for Kong deployment to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/kong-kong -n kong

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "                 KONG INSTALLATION COMPLETE                       " -ForegroundColor Cyan

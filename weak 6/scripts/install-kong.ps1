# install-kong.ps1
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                INSTALLING KONG API GATEWAY                       " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# Add Kong Helm repo
$chartVersion = "0.24.0"
helm repo add kong https://charts.konghq.com
helm repo update

# Install Kong in the 'kong' namespace
Write-Host "`nInstalling Kong Ingress Controller..." -ForegroundColor Yellow
helm upgrade --install kong kong/ingress --version $chartVersion -n kong --create-namespace --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { throw "Kong Helm chart installation failed." }

Write-Host "`nWaiting for Kong deployment to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/kong-kong -n kong --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "Kong Ingress Controller did not become ready." }

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "                 KONG INSTALLATION COMPLETE                       " -ForegroundColor Cyan

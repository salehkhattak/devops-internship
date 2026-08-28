# deploy-app.ps1
$Namespace = "parallax"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "      DEPLOYING APPLICATION & KONG PLUGINS                        " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

Write-Host "`n[1/3] Deploying Helm release parallax-release into namespace $Namespace..." -ForegroundColor Yellow
helm upgrade --install parallax-release "weak 6/parallax-app" -n $Namespace --create-namespace

Write-Host "`n[2/3] Applying Kong Plugins & Consumer..." -ForegroundColor Yellow
kubectl apply -f "weak 6/kong/rate-limit-plugin.yaml"
kubectl apply -f "weak 6/kong/key-auth-plugin.yaml"
kubectl apply -f "weak 6/kong/consumer.yaml"

Write-Host "`n[3/3] Waiting for application to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/parallax-release-parallax-app-frontend -n $Namespace
kubectl rollout status deployment/parallax-release-parallax-app-backend -n $Namespace

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "         APPLICATION DEPLOYED & PLUGINS ENFORCED                 " -ForegroundColor Cyan

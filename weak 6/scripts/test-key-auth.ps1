# test-key-auth.ps1
Write-Host "Starting port-forward for Kong proxy..." -ForegroundColor Yellow
$job = Start-Job { kubectl port-forward svc/kong-kong-proxy -n kong 8080:80 }
Start-Sleep -Seconds 5

$url = "http://localhost:8080/api"
$hostHeader = "parallax.local"
$apiKey = "secret123"

Write-Host "`n[Test 1] Request WITHOUT API Key..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $url -Headers @{ "Host" = $hostHeader } -Method Get -UseBasicParsing -ErrorAction Stop
    Write-Host "Status Code $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[Test 2] Request WITH Valid API Key..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $url -Headers @{ "Host" = $hostHeader; "apikey" = $apiKey } -Method Get -UseBasicParsing -ErrorAction Stop
    Write-Host "Status Code $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nStopping port-forward..." -ForegroundColor Yellow
Stop-Job $job
Remove-Job $job

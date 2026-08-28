# test-rate-limiting.ps1
Write-Host "Starting port-forward for Kong proxy..." -ForegroundColor Yellow
$job = Start-Job { kubectl port-forward svc/kong-kong-proxy -n kong 8080:80 }
Start-Sleep -Seconds 5

$url = "http://localhost:8080/"
$hostHeader = "parallax.local"

Write-Host "`nSending 10 rapid requests to test rate limiting (limit is 5/min)..." -ForegroundColor Cyan
for ($i = 1; $i -le 10; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $url -Headers @{ "Host" = $hostHeader } -Method Get -UseBasicParsing -ErrorAction Stop
        Write-Host "Request $i : Status Code $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Request $i : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nStopping port-forward..." -ForegroundColor Yellow
Stop-Job $job
Remove-Job $job

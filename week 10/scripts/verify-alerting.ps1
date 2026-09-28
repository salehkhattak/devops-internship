$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$week10 = Join-Path $root "week 10"
$testRule = Join-Path $week10 "verification\trigger-test-alert.yaml"
$startedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$received = $false

kubectl apply -f $testRule
if ($LASTEXITCODE -ne 0) { throw "Could not create the temporary delivery test alert." }

try {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        $logs = kubectl logs deployment/alertmanager-webhook -n monitoring --since-time=$startedAt 2>$null
        if (($logs -join "`n") -match "Week10AlertmanagerDeliveryTest") {
            $received = $true
            break
        }
        Start-Sleep -Seconds 5
    }

    if (-not $received) {
        $logs = kubectl logs deployment/alertmanager-webhook -n monitoring --since-time=$startedAt 2>$null
        throw "No test notification reached the mock webhook within 150 seconds. Receiver logs:`n$($logs -join "`n")"
    }

    Write-Host "Verified: Alertmanager delivered Week10AlertmanagerDeliveryTest to the mock webhook."
}
finally {
    kubectl delete -f $testRule --ignore-not-found=true | Out-Null
}
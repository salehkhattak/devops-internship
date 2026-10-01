$ErrorActionPreference = "Stop"

$week11 = Resolve-Path (Join-Path $PSScriptRoot "..")
$analysisTemplate = Join-Path $week11 "monitoring\canary-analysis.yaml"
$namespace = "parallax"
$rollout = "parallax-frontend"
$stableService = "parallax-release-parallax-app-frontend"
$failureObserved = $false

$phase = kubectl get rollout $rollout -n $namespace -o jsonpath="{.status.phase}"
if ($LASTEXITCODE -ne 0 -or $phase -ne "Healthy") {
    throw "The canary rollback test requires a Healthy rollout; current phase is '$phase'."
}

try {
    kubectl patch analysistemplates.argoproj.io parallax-canary-metrics -n $namespace --type=json `
        -p '[{"op":"replace","path":"/spec/metrics/0/successCondition","value":"result[0] < -1"}]'
    if ($LASTEXITCODE -ne 0) { throw "Could not install the temporary failing metric threshold." }

    $testId = [DateTime]::UtcNow.ToString("yyyyMMddHHmmss")
    $patch = '{"spec":{"template":{"metadata":{"annotations":{"week11.parallax.dev/rollback-test":"' + $testId + '"}}}}}'
    kubectl patch rollout $rollout -n $namespace --type=merge -p $patch
    if ($LASTEXITCODE -ne 0) { throw "Could not start the test Rollout revision." }

    $deadline = (Get-Date).AddMinutes(6)
    do {
        $phase = kubectl get rollout $rollout -n $namespace -o jsonpath="{.status.phase}"
        if ($LASTEXITCODE -ne 0) { throw "Could not read Rollout status." }
        if ($phase -eq "Degraded") {
            $failureObserved = $true
            break
        }
        if ($phase -eq "Healthy") { throw "The intentionally failing Prometheus analysis did not abort the rollout." }
        Start-Sleep -Seconds 5
    } while ((Get-Date) -lt $deadline)

    if (-not $failureObserved) { throw "Timed out waiting for the failed metric analysis to abort the Rollout." }

    $stableHash = kubectl get rollout $rollout -n $namespace -o jsonpath="{.status.stableRS}"
    $serviceHash = kubectl get service $stableService -n $namespace -o jsonpath="{.spec.selector.rollouts-pod-template-hash}"
    if ($LASTEXITCODE -ne 0 -or -not $stableHash -or $serviceHash -ne $stableHash) {
        throw "The stable Service is not selecting the stable ReplicaSet after the failed analysis."
    }

    Write-Host "Metric-gated rollback verified: rollout degraded and stable Service points to $stableHash."
}
finally {
    kubectl apply -f $analysisTemplate
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not restore the production AnalysisTemplate." }

    kubectl patch rollout $rollout -n $namespace --type=merge `
        -p '{"spec":{"template":{"metadata":{"annotations":{"week11.parallax.dev/rollback-test":null}}}}}'
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not remove the temporary test annotation." }

    kubectl -n $namespace rollout status rollout/$rollout --timeout=300s
    if ($LASTEXITCODE -ne 0) { Write-Warning "The Rollout did not return to Healthy after restoring the production threshold." }
}

if (-not $failureObserved) { exit 1 }
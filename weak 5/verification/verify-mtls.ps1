# Week 5: Istio Strict mTLS Verification Script (PowerShell)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "         ISTIO STRICT mTLS NETWORKING VERIFICATION                " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$Namespace = "parallax"
$LegacyNs = "legacy"
$BackendSvc = "parallax-release-parallax-app-backend.parallax.svc.cluster.local"
$BackendPort = "5000"

Write-Host "`n[1/3] Verifying Sidecar Injection in Namespace: $Namespace" -ForegroundColor Yellow
$FrontendPod = (kubectl get pod -n $Namespace -l app=frontend -o jsonpath='{.items[0].metadata.name}')
Write-Host "Frontend Pod: $FrontendPod"

$Containers = (kubectl get pod -n $Namespace $FrontendPod -o jsonpath='{.spec.containers[*].name}')
Write-Host "Containers in Pod: $Containers"

Write-Host "`n[2/3] Testing Injected Pod -> Backend Communication (Should SUCCEED with mTLS)" -ForegroundColor Yellow
Write-Host "Executing curl from $FrontendPod in $Namespace to http://${BackendSvc}:${BackendPort}/health..."
kubectl exec -n $Namespace $FrontendPod -c frontend -- wget -qO- "http://${BackendSvc}:${BackendPort}/health"

Write-Host "`n[3/3] Testing Un-injected Pod -> Backend Communication (Should FAIL due to Strict mTLS)" -ForegroundColor Yellow
Write-Host "Deploying un-injected pod curler-uninjected in namespace $LegacyNs..."
kubectl apply -f "weak 5/verification/uninjected-pod.yaml"
kubectl wait --for=condition=Ready pod/curler-uninjected -n $LegacyNs --timeout=60s

Write-Host "Executing curl from un-injected pod in $LegacyNs namespace..."
$Result = kubectl exec -n $LegacyNs curler-uninjected -- curl -v --connect-timeout 5 "http://${BackendSvc}:${BackendPort}/health" 2>&1

Write-Host "`nRaw Output from Un-injected Pod:" -ForegroundColor Gray
Write-Host $Result

if ($LASTEXITCODE -ne 0 -or $Result -match "Connection reset" -or $Result -match "command terminated with exit code") {
    Write-Host "`n✅ SUCCESS: Connection from un-injected pod failed as expected!" -ForegroundColor Green
    Write-Host "Strict mTLS is actively blocking non-mesh traffic." -ForegroundColor Green
} else {
    Write-Host "`n❌ FAILURE: Un-injected pod was able to communicate! Check PeerAuthentication settings." -ForegroundColor Red
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "         ISTIO STRICT mTLS VERIFICATION COMPLETE                 " -ForegroundColor Cyan

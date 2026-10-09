param(
    [Parameter(Mandatory = $true)]
    [string]$ImageTag,

    [Parameter(Mandatory = $true)]
    [string]$KongUrl,

    [Parameter(Mandatory = $true)]
    [string]$PrometheusUrl,

    [Parameter(Mandatory = $true)]
    [string]$GrafanaUrl,

    [int]$PrometheusTimeoutSeconds = 90
)

$ErrorActionPreference = "Stop"
$namespace = "parallax"
$deployments = @(
    @{ Name = "parallax-release-parallax-app-frontend"; Container = "frontend" },
    @{ Name = "parallax-release-parallax-app-backend"; Container = "backend" }
)

function Get-KubernetesJson {
    param([string[]]$Arguments)

    $output = & kubectl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl $($Arguments -join ' ') failed."
    }
    return ($output -join "`n" | ConvertFrom-Json)
}

function Assert-HttpSuccess {
    param([string]$Uri)

    $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 15
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 400) {
        throw "HTTP check failed for $Uri with status $($response.StatusCode)."
    }
    return $response
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required. Configure the target Kubernetes context and retry."
}

$application = Get-KubernetesJson @("get", "application", "parallax-app", "-n", "argocd", "-o", "json")
if ($application.status.sync.status -ne "Synced") {
    throw "ArgoCD application parallax-app is not Synced (status: $($application.status.sync.status))."
}
if ($application.status.health.status -ne "Healthy") {
    throw "ArgoCD application parallax-app is not Healthy (status: $($application.status.health.status))."
}
Write-Host "PASS ArgoCD: $($application.status.sync.status) / $($application.status.health.status), revision $($application.status.sync.revision)"

foreach ($item in $deployments) {
    $deployment = Get-KubernetesJson @("get", "deployment", $item.Name, "-n", $namespace, "-o", "json")
    $container = @($deployment.spec.template.spec.containers | Where-Object { $_.name -eq $item.Container })
    if ($container.Count -ne 1) {
        throw "$($item.Name) does not contain exactly one '$($item.Container)' container."
    }
    if ($container[0].image -notlike "*:$ImageTag") {
        throw "$($item.Name) is not running the expected image tag '$ImageTag'."
    }
    if ($deployment.status.availableReplicas -lt $deployment.spec.replicas) {
        throw "$($item.Name) has $($deployment.status.availableReplicas) available replicas; expected $($deployment.spec.replicas)."
    }
    Write-Host "PASS deployment: $($item.Name) runs $($container[0].image) with all replicas available"
}

$ingresses = Get-KubernetesJson @("get", "ingress", "-n", $namespace, "-o", "json")
$kongIngress = @(
    $ingresses.items | Where-Object {
        $_.spec.ingressClassName -eq "kong" -and
        (@($_.spec.rules | Where-Object { $_.host -eq "parallax.local" }).Count -gt 0)
    }
)
if ($kongIngress.Count -eq 0) {
    throw "No Kong Ingress for parallax.local exists in namespace $namespace."
}
$kongBaseUrl = $KongUrl.TrimEnd("/")
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    throw "curl.exe is required to send the parallax.local Host header through the Kong port-forward."
}
& curl.exe --silent --show-error --fail --max-time 15 --output NUL --header "Host: parallax.local" $kongBaseUrl
if ($LASTEXITCODE -ne 0) {
    throw "Kong did not return a successful response for the parallax.local route at $KongUrl."
}
Write-Host "PASS Kong: parallax.local route returned a successful HTTP response from $KongUrl"

$backendStatus = & curl.exe --silent --show-error --fail --max-time 15 --header "Host: parallax.local" --header "apikey: secret123" "$kongBaseUrl/api/backend-status"
if ($LASTEXITCODE -ne 0) {
    throw "The Kong-routed backend status endpoint failed at $KongUrl/api/backend-status."
}
$backendResult = ($backendStatus -join "`n" | ConvertFrom-Json)
if (-not $backendResult.success -or $backendResult.statusCode -ne 200) {
    throw "The backend status endpoint did not confirm a successful service request."
}
Write-Host "PASS backend: Kong-routed /api/backend-status reports success"

$prometheusBaseUrl = $PrometheusUrl.TrimEnd("/")
$queryUri = "$prometheusBaseUrl/api/v1/query?query=$([uri]::EscapeDataString('kong_http_requests_total'))"
$deadline = (Get-Date).AddSeconds($PrometheusTimeoutSeconds)
$metricResult = $null
do {
    $metricResult = Invoke-RestMethod -Uri $queryUri -TimeoutSec 15
    if ($metricResult.status -ne "success") {
        throw "Prometheus returned a non-success response for kong_http_requests_total."
    }
    if (@($metricResult.data.result).Count -gt 0) {
        break
    }
    Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)
if (@($metricResult.data.result).Count -eq 0) {
    throw "Prometheus did not return kong_http_requests_total within $PrometheusTimeoutSeconds seconds. Check the Kong ServiceMonitor and Prometheus targets."
}
Write-Host "PASS Prometheus: Kong request metrics are queryable"

$null = Assert-HttpSuccess -Uri "$($GrafanaUrl.TrimEnd('/'))/api/health"
$dashboard = Get-KubernetesJson @("get", "configmap", "parallax-observability-dashboard", "-n", "monitoring", "-o", "json")
if ($dashboard.data.'parallax-observability.json' -notmatch '"title":\s*"Parallax Services and Kong"') {
    throw "The provisioned Parallax Grafana dashboard is missing or has an unexpected title."
}
$grafanaDeployment = Get-KubernetesJson @("get", "deployment", "kube-prometheus-stack-grafana", "-n", "monitoring", "-o", "json")
if ($grafanaDeployment.status.availableReplicas -lt 1) {
    throw "The Grafana deployment has no available replicas."
}
Write-Host "PASS Grafana: API is healthy, dashboard is provisioned, and a replica is available"
Write-Host "End-to-end demo checks passed. Open Grafana and capture the live dashboard as demo evidence."

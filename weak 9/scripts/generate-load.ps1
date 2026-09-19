param(
  [string]$BaseUrl = "http://localhost:8080",
  [int]$Requests = 300,
  [int]$ErrorEvery = 10
)

$ErrorActionPreference = "Stop"

$success = 0
$failure = 0

Write-Host "Sending $Requests requests to $BaseUrl (1 error every $ErrorEvery requests)..."

1..$Requests | ForEach-Object {
  try {
    $path = if ($_ % $ErrorEvery -eq 0) { "/week-9-intentional-404" } else { "/" }
    $response = Invoke-WebRequest -Uri "$BaseUrl$path" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
      $success++
    } else {
      $failure++
    }
  } catch {
    $failure++
  }
}

Write-Host "`nTraffic Generation Completed:"
Write-Host " - Total Requests : $Requests"
Write-Host " - Successful (2xx): $success"
Write-Host " - Failed / 404   : $failure"

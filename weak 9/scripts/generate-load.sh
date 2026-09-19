#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
REQUESTS="${2:-300}"
ERROR_EVERY="${3:-10}"

success=0
failure=0

echo "Sending $REQUESTS requests to $BASE_URL (1 error every $ERROR_EVERY requests)..."

for ((i=1; i<=REQUESTS; i++)); do
  if (( i % ERROR_EVERY == 0 )); then
    path="/week-9-intentional-404"
  else
    path="/"
  fi

  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$BASE_URL$path" || echo "000")
  if [[ "$http_code" =~ ^[23] ]]; then
    ((success++))
  else
    ((failure++))
  fi
done

echo ""
echo "Traffic Generation Completed:"
echo " - Total Requests : $REQUESTS"
echo " - Successful (2xx): $success"
echo " - Failed / 404   : $failure"

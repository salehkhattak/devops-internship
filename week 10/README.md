# Week 10: Alerting and Runbooks

This week layers Alertmanager configuration and service-health alerts onto the Prometheus and Grafana stack from Week 9. Notifications are sent to an in-cluster mock webhook, which records received payloads in its pod logs. No external Slack or email credentials are required.

## Contents

```text
week 10/
├── monitoring/
│   ├── alertmanager-values.yaml  # Alertmanager route and mock webhook receiver
│   ├── alertmanager-webhook.yaml # Logging webhook Deployment and Service
│   └── prometheus-rules.yaml     # Latency, 5xx, and CrashLoopBackOff alerts
├── scripts/
│   ├── install-alerting.ps1      # Installs Week 9 stack, then configures Week 10 alerting
│   └── verify-alerting.ps1       # Fires a temporary test alert and checks receiver logs
└── verification/
    └── trigger-test-alert.yaml  # Temporary PrometheusRule used by the verification script
```

## Prerequisites

- A Kubernetes cluster with the Parallax application deployed in namespace `parallax`.
- Helm 3 and `kubectl`, configured to access that cluster.
- Week 9's monitoring manifests and scripts in the sibling `weak 9/` directory.

## Install

From the repository root in PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 10\scripts\install-alerting.ps1"
```

The script installs the Week 9 stack and scrape configuration, deploys the mock webhook, applies the Week 10 Alertmanager Helm values, and registers the Prometheus rules.

## Alerts and Response Runbook

| Alert | Severity | Trigger | Response |
|---|---|---|---|
| `ParallaxHighLatency` | Warning | Istio p95 request latency in the `parallax` namespace exceeds 1,000 ms for 5 minutes. | Check the Grafana service latency and request-rate panels. Inspect frontend/backend pod CPU and memory, recent deployments, and downstream dependency latency. Roll back or scale the affected service if a recent change or resource saturation is responsible. Confirm p95 returns below 1,000 ms. |
| `ParallaxHighErrorRate` | Critical | More than 5% of Istio requests in `parallax` return HTTP 5xx for 2 minutes. | Check the Grafana error-rate panel and inspect affected service logs with `kubectl logs -n parallax deploy/<deployment> --since=10m`. Check backend health, recent rollouts, and service endpoints. Restore the last known healthy version or dependency, then verify 5xx rates fall below 5%. |
| `ParallaxPodCrashLooping` | Critical | A container in `parallax` remains in `CrashLoopBackOff` for 2 minutes. | Identify the pod with `kubectl get pods -n parallax` and inspect `kubectl describe pod -n parallax <pod>` and `kubectl logs -n parallax <pod> --previous`. Correct the startup/configuration or dependency failure, then verify replacement pods become Ready and the alert resolves. |

Critical alerts are sent immediately; warnings are grouped for 30 seconds. Both severities use the same mock webhook receiver, with resolved notifications enabled. The thresholds are starting points and should be tuned against observed baseline traffic.

## Deliberately Trigger and Verify Delivery

Run the verification script after installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 10\scripts\verify-alerting.ps1"
```

It creates a temporary always-firing Prometheus rule, waits up to 150 seconds for `Week10AlertmanagerDeliveryTest` to appear in the mock receiver's logs, reports success/failure, and removes the temporary rule in a `finally` block. This exercises Prometheus rule discovery, Alertmanager routing, and webhook delivery without disrupting application pods. The three operational alerts fire from their respective metric conditions.

To inspect receiver payloads manually:

```powershell
kubectl logs -n monitoring deployment/alertmanager-webhook --since=10m
```

## Troubleshooting

- Check all components: `kubectl get pods -n monitoring`.
- Check installed rules: `kubectl get prometheusrule -n monitoring`.
- Check Alertmanager targets/configuration: port-forward with `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093`, then open `http://localhost:9093`.
- If no operational alert appears, confirm its metrics exist in Prometheus and the Week 9 Istio/Kong scrapes are healthy. The latency and error alerts require traffic; CrashLoopBackOff requires a crashing application container.
- If the receiver is unavailable, inspect `kubectl describe pod -n monitoring -l app=alertmanager-webhook` and its logs. The receiver is a test sink only, not a durable production notification service.
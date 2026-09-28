# Week 11: Alerting and Runbooks

This week carries the Week 10 Alertmanager implementation forward as a repeatable deployment. It layers severity-based notification routing, three Parallax service-health alerts, an in-cluster mock webhook, and a deliberate delivery test onto the Week 9 Prometheus/Grafana stack.

## Contents

```text
week 11/
├── monitoring/
│   ├── alertmanager-values.yaml
│   ├── alertmanager-webhook.yaml
│   └── prometheus-rules.yaml
├── scripts/
│   ├── install-alerting.ps1
│   └── verify-alerting.ps1
└── verification/
    └── trigger-test-alert.yaml
```

## Prerequisites and Installation

- Kubernetes with the Parallax application in namespace `parallax`.
- Helm 3 and `kubectl` configured for the cluster.
- Week 9 monitoring files in the sibling `weak 9/` directory.

From the repository root in PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 11\scripts\install-alerting.ps1"
```

The installer deploys the Week 9 monitoring stack, applies this week's Alertmanager receiver configuration, and registers the three alert rules.

## Alert Runbook

| Alert | Severity | Trigger | Response |
|---|---|---|---|
| `ParallaxHighLatency` | Warning | Istio p95 latency in `parallax` exceeds 1,000 ms for 5 minutes. | Inspect Grafana latency/request-rate panels, pod CPU/memory, recent deployments, and downstream latency. Roll back or scale the responsible service if indicated; confirm p95 is below 1,000 ms. |
| `ParallaxHighErrorRate` | Critical | More than 5% of Istio requests in `parallax` return 5xx for 2 minutes. | Review the error-rate panel and `kubectl logs -n parallax deploy/<deployment> --since=10m`. Check backend health, service endpoints, and recent rollouts. Restore the last known healthy version/dependency and confirm 5xx falls below 5%. |
| `ParallaxPodCrashLooping` | Critical | A container in `parallax` stays in `CrashLoopBackOff` for 2 minutes. | Run `kubectl describe pod -n parallax <pod>` and `kubectl logs -n parallax <pod> --previous`. Fix startup/configuration or dependency failures; confirm replacement pods become Ready and the alert resolves. |

Critical notifications route immediately; warnings wait 30 seconds for grouping. Resolved alerts are also sent. Tune thresholds against observed traffic before treating them as production SLOs.

## Trigger and Verify a Notification

After installation, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 11\scripts\verify-alerting.ps1"
```

The script applies a temporary always-firing rule, waits up to 150 seconds for `Week11AlertmanagerDeliveryTest` in the mock webhook logs, then removes the rule. This checks rule discovery, routing, and delivery without killing application pods. To inspect received payloads manually, run `kubectl logs -n monitoring deployment/alertmanager-webhook --since=10m`.

## Troubleshooting

- Check pod state: `kubectl get pods -n monitoring`.
- Check registered rules: `kubectl get prometheusrule -n monitoring`.
- Inspect Alertmanager at `http://localhost:9093` after running `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093`.
- If the three operational rules do not fire, confirm their metrics and Week 9 scrape targets exist. Latency/error alerts need traffic; CrashLoopBackOff needs a failing container.
- The mock receiver stores notifications in pod logs and is for verification only, not durable production alerting.
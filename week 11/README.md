# Week 11: Metric-Gated Canary Deployments

This week extends the Week 9 Prometheus/Istio telemetry with Argo Rollouts. The frontend is progressively shifted through 10%, 25%, 50%, and 100% canary traffic using Istio weighted routing. At every stage, Prometheus checks the canary's 5xx ratio and p95 latency; a failed analysis aborts the rollout and restores 100% stable traffic.

## Contents

```text
week 11/
├── monitoring/
│   └── canary-analysis.yaml       # Prometheus error-rate and p95 gates
├── rollout/
│   └── canary.yaml                # Istio Gateway, VirtualService, Services, Rollout
├── scripts/
│   ├── install-canary.ps1         # Installs monitoring, controller, and canary resources
│   └── verify-canary-rollback.ps1 # Forces metric analysis failure and verifies rollback
└── verification/
```

## Prerequisites and Install

- A Kubernetes cluster with Istio installed, including the `istio-ingressgateway` workload, and Helm 3 / `kubectl` configured.
- The Week 5 Helm chart and Week 10 alerting deliverable in sibling `weak 5/` and `week 10/` directories. Week 10 installs the Week 9 Prometheus stack.
- Prometheus Operator CRDs installed by the Week 9 kube-prometheus-stack.

From the repository root in PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 11\scripts\install-canary.ps1"
```

The installer applies the Week 10 Alertmanager/Prometheus setup, installs the Argo Rollouts controller, disables the chart-managed frontend Deployment, and creates the Rollout resources. The backend remains managed by the Week 5 Helm release. Route external frontend requests through the Istio ingress gateway using host `parallax.local`; direct requests to old NodePort addresses do not pass through the weighted VirtualService.

The initial canary image is `salehktk005/simple-node-app:v1`. For a release, set the image on `rollout/canary.yaml` to the new immutable image tag and apply it:

```powershell
kubectl apply -f ".\week 11\rollout\canary.yaml"
```

## Promotion and Automated Rollback

| Stage | Traffic to canary | Gate |
|---|---:|---|
| 1 | 10% | 2-minute observation, then three Prometheus measurements |
| 2 | 25% | 2-minute observation, then three Prometheus measurements |
| 3 | 50% | 2-minute observation, then three Prometheus measurements |
| 4 | 100% | 2-minute observation, then final analysis before promotion |

Each analysis interval is one minute. It aborts if no canary traffic is observed, the canary 5xx ratio is at least 5%, or p95 latency is at least 1,000 ms. The queries select Istio metrics for the canary Service specifically, and a missing traffic signal fails closed rather than treating absent metrics as healthy.

On analysis failure, Argo Rollouts aborts the update, resets the Istio route to 100% stable, and keeps the stable ReplicaSet serving. Investigate the failed AnalysisRun and canary logs before publishing another image:

```powershell
kubectl get rollout parallax-frontend -n parallax -o wide
kubectl get analysisrun -n parallax
kubectl logs -n parallax -l app=frontend,rollout=parallax-frontend --all-containers --since=10m
```

Fix the application or configuration, publish a new image tag, update the image in `rollout/canary.yaml`, and apply it to begin a new rollout.

## Verify a Failed-Metric Rollback

Run after installation, while the rollout is `Healthy`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\week 11\scripts\verify-canary-rollback.ps1"
```

The test temporarily changes the error-rate success threshold to an impossible value, triggers a new Rollout revision, and waits for Argo Rollouts to mark it `Degraded`. It verifies that the stable Service selects the stable ReplicaSet, restores the production analysis threshold, and returns the Rollout to `Healthy`. No application code or image is modified by the test.

## Troubleshooting

- Check `kubectl get pods -n argo-rollouts` and `kubectl get rollout -n parallax`.
- Confirm Prometheus is reachable at `kube-prometheus-stack-prometheus.monitoring.svc:9090` and inspect `kubectl get analysisrun -n parallax`.
- Check the Istio route with `kubectl get virtualservice parallax-frontend -n parallax -o yaml`; weighted destinations are updated by the Rollouts controller.
- `kubectl get gateway,virtualservice -n parallax` should show the frontend gateway and route. Requests sent directly to the Service from a non-mesh client bypass Istio traffic weighting.
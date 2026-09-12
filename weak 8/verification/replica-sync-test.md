# Replica Sync Test

This test proves that a Git change is reconciled by ArgoCD without a manual deployment command.

## Procedure

1. Confirm the baseline:

   ```bash
   date -u
   kubectl -n parallax get deployment parallax-frontend -o wide
   argocd app get parallax-app
   ```

   Record the UTC time and confirm `frontend.replicaCount: 2` is healthy.

2. Change only `frontend.replicaCount` in `weak 4/parallax-app/values.yaml` from `2` to `3`.

3. Commit and push the change. Record the exact GitHub push time in UTC.

4. Watch ArgoCD and Kubernetes:

   ```bash
   argocd app get parallax-app --refresh
   kubectl -n parallax get deployment parallax-frontend -w
   argocd app wait parallax-app --sync --health --timeout 180
   ```

5. Record the first time the deployment reports three available replicas and calculate:

   ```text
   sync duration = first healthy 3-replica timestamp - GitHub push timestamp
   ```

## Results

| Item | Value |
|---|---|
| Git commit | Fill after push |
| GitHub push time (UTC) | Fill during test |
| First observed 3 replicas (UTC) | Fill during test |
| Sync duration | Fill during test |
| Final ArgoCD status | Expected: Synced / Healthy |
| Notification test | Expected: Slack message on sync failure |

The duration depends on ArgoCD's reconciliation interval, repository size, image availability, and cluster scheduling. Do not invent a duration: record the value observed in the target cluster.
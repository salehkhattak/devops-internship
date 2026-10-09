$ErrorActionPreference = "Stop"
$argocdVersion = "v3.5.4"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/$argocdVersion/manifests/install.yaml"
if ($LASTEXITCODE -ne 0) { throw "ArgoCD $argocdVersion installation failed." }
kubectl -n argocd rollout status deployment/argocd-server --timeout=180s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=180s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=180s
Write-Host "ArgoCD is installed in namespace argocd."
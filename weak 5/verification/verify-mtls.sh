#!/usr/bin/env bash
# Week 5: Istio Strict mTLS Verification Script

set -e

echo "=================================================================="
echo "         ISTIO STRICT mTLS NETWORKING VERIFICATION                "
echo "=================================================================="

NAMESPACE="parallax"
LEGACY_NS="legacy"
BACKEND_SVC="parallax-release-parallax-app-backend.parallax.svc.cluster.local"
BACKEND_PORT="5000"

echo ""
echo "[1/3] Verifying Sidecar Injection in Namespace: ${NAMESPACE}"
echo "------------------------------------------------------------------"
FRONTEND_POD=$(kubectl get pod -n ${NAMESPACE} -l app=frontend -o jsonpath='{.items[0].metadata.name}')
CONTAINER_COUNT=$(kubectl get pod -n ${NAMESPACE} ${FRONTEND_POD} -o jsonpath='{.spec.containers[*].name}' | wc -w)

echo "Frontend Pod: ${FRONTEND_POD}"
echo "Container count in pod: ${CONTAINER_COUNT} (Expected: 2 -> application + istio-proxy)"

echo ""
echo "[2/3] Testing Injected Pod -> Backend Communication (Should SUCCEED with mTLS)"
echo "------------------------------------------------------------------"
echo "Executing curl from ${FRONTEND_POD} in ${NAMESPACE} to http://${BACKEND_SVC}:${BACKEND_PORT}/health..."
kubectl exec -n "$NAMESPACE" "$FRONTEND_POD" -c frontend -- wget -qO- "http://${BACKEND_SVC}:${BACKEND_PORT}/health"

echo ""
echo "[3/3] Testing Un-injected Pod -> Backend Communication (Should FAIL due to Strict mTLS)"
echo "------------------------------------------------------------------"
echo "Deploying un-injected pod curler-uninjected in namespace ${LEGACY_NS} if not present..."
kubectl apply -f weak\ 5/verification/uninjected-pod.yaml
kubectl wait --for=condition=Ready pod/curler-uninjected -n ${LEGACY_NS} --timeout=60s

echo "Executing curl from un-injected pod in ${LEGACY_NS} namespace..."
set +e
kubectl exec -n ${LEGACY_NS} curler-uninjected -- curl -v --connect-timeout 5 "http://${BACKEND_SVC}:${BACKEND_PORT}/health"
EXIT_CODE=$?
set -e

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "✅ SUCCESS: Connection from un-injected pod failed as expected!"
  echo "Strict mTLS is actively blocking non-mesh traffic."
else
  echo ""
  echo "❌ FAILURE: Un-injected pod was able to communicate! Check PeerAuthentication settings."
  exit 1
fi

echo ""
echo "=================================================================="
echo "         ISTIO STRICT mTLS VERIFICATION COMPLETE                 "
echo "=================================================================="

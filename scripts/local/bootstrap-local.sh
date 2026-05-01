#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

wait_for_deployment() {
  local namespace="$1"
  local deployment="$2"
  local timeout="$3"

  if kubectl -n "${namespace}" wait "deployment/${deployment}" --for=condition=Available --timeout=10s >/dev/null 2>&1; then
    echo "[OK] deployment/${deployment} is already Available"
    return 0
  fi

  echo "[INFO] Restarting deployment/${deployment} to recover from a stale failed rollout state"
  kubectl -n "${namespace}" rollout restart "deployment/${deployment}" >/dev/null
  kubectl -n "${namespace}" rollout status "deployment/${deployment}" --timeout="${timeout}"
}

"${SCRIPT_DIR}/create-k3d-cluster.sh"
"${SCRIPT_DIR}/install-operators.sh"
kubectl apply -k "${REPO_ROOT}/k8s/overlays/local"

echo "[INFO] Waiting for MinIO and Postgres to be ready"
wait_for_deployment data-platform minio 180s
wait_for_deployment data-platform postgres 180s

echo "[INFO] Waiting for Stackable services to be ready"
kubectl -n data-platform wait HiveCluster/hive-metastore --for=condition=Available --timeout=300s
kubectl -n data-platform wait TrinoCluster/trino --for=condition=Available --timeout=300s

"${SCRIPT_DIR}/smoke-test.sh"
"${SCRIPT_DIR}/load-sample-data.sh"

echo "[OK] Local end-to-end bootstrap completed"

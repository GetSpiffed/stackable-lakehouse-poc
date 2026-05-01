#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

"${SCRIPT_DIR}/create-k3d-cluster.sh"
"${SCRIPT_DIR}/install-operators.sh"
kubectl apply -k "${REPO_ROOT}/k8s/overlays/local"

echo "[INFO] Waiting for MinIO and Postgres to be ready"
kubectl -n data-platform rollout status deployment/minio --timeout=120s
kubectl -n data-platform rollout status deployment/postgres --timeout=120s

echo "[INFO] Waiting for Stackable services to be ready"
kubectl -n data-platform wait HiveCluster/hive-metastore --for=condition=Available --timeout=300s
kubectl -n data-platform wait TrinoCluster/trino --for=condition=Available --timeout=300s

"${SCRIPT_DIR}/smoke-test.sh"
"${SCRIPT_DIR}/load-sample-data.sh"

echo "[OK] Local end-to-end bootstrap completed"

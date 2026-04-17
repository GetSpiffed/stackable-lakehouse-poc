#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

"${SCRIPT_DIR}/create-k3d-cluster.sh"
"${SCRIPT_DIR}/install-operators.sh"
kubectl apply -k "${REPO_ROOT}/k8s/base/overlays/local"

# Give operators/workloads some time and verify
"${SCRIPT_DIR}/smoke-test.sh"
"${SCRIPT_DIR}/load-sample-data.sh"

echo "[OK] Local end-to-end bootstrap completed"

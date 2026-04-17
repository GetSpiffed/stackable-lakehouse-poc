#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-stackable-poc}"
K3D_SERVERS="${K3D_SERVERS:-1}"
K3D_AGENTS="${K3D_AGENTS:-1}"
K3D_WAIT="${K3D_WAIT:-true}"

required_cmds=(k3d kubectl docker helm)
for cmd in "${required_cmds[@]}"; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "[ERROR] Missing required command: ${cmd}" >&2
    exit 1
  fi
done

if k3d cluster list | awk '{print $1}' | grep -qx "${CLUSTER_NAME}"; then
  echo "[INFO] k3d cluster '${CLUSTER_NAME}' already exists; skipping create"
else
  echo "[INFO] Creating k3d cluster '${CLUSTER_NAME}'"
  k3d cluster create "${CLUSTER_NAME}" \
    --servers "${K3D_SERVERS}" \
    --agents "${K3D_AGENTS}" \
    --wait
fi

kubectl config use-context "k3d-${CLUSTER_NAME}" >/dev/null

if [[ "${K3D_WAIT}" == "true" ]]; then
  echo "[INFO] Waiting for nodes to become Ready"
  kubectl wait --for=condition=Ready node --all --timeout=180s
fi

echo "[OK] k3d cluster '${CLUSTER_NAME}' is ready"
kubectl get nodes -o wide

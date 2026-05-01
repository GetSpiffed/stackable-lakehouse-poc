#!/usr/bin/env bash
set -eu

STACKABLE_VERSION="${STACKABLE_VERSION:-26.3.0}"
OPERATORS=(commons secret listener hive trino)
NAMESPACE="stackable-operators"

for op in "${OPERATORS[@]}"; do
  release="${op}-operator"
  chart="oci://oci.stackable.tech/sdp-charts/${release}"

  if helm status "${release}" --namespace "${NAMESPACE}" >/dev/null 2>&1; then
    echo "[INFO] Upgrading ${release} to ${STACKABLE_VERSION}"
    helm upgrade --wait --namespace "${NAMESPACE}" "${release}" "${chart}" --version "${STACKABLE_VERSION}"
  else
    echo "[INFO] Installing ${release} ${STACKABLE_VERSION}"
    helm install --wait --namespace "${NAMESPACE}" --create-namespace "${release}" "${chart}" --version "${STACKABLE_VERSION}"
  fi
done

echo "[OK] Stackable operators installed"

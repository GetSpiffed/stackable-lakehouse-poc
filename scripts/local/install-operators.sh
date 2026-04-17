#!/usr/bin/env bash
set -euo pipefail

STACKABLE_VERSION="${STACKABLE_VERSION:-26.3.0}"
OPERATORS=(commons secret listener hive trino)

for op in "${OPERATORS[@]}"; do
  release="${op}-operator"
  chart="oci://oci.stackable.tech/sdp-charts/${release}"

  if helm status "${release}" >/dev/null 2>&1; then
    echo "[INFO] Upgrading ${release} to ${STACKABLE_VERSION}"
    helm upgrade --wait "${release}" "${chart}" --version "${STACKABLE_VERSION}"
  else
    echo "[INFO] Installing ${release} ${STACKABLE_VERSION}"
    helm install --wait "${release}" "${chart}" --version "${STACKABLE_VERSION}"
  fi
done

echo "[OK] Stackable operators installed"

#!/usr/bin/env bash
set -eu

NAMESPACE="${NAMESPACE:-data-platform}"
TRINO_SERVICE="${TRINO_SERVICE:-trino-coordinator-default}"
TRINO_PORT="${TRINO_PORT:-8080}"
SAMPLE_BUCKET="${SAMPLE_BUCKET:-lakehouse}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SQL_SCHEMA_FILE="${REPO_ROOT}/k8s/base/dataset/create-schema.sql"
SQL_TABLE_FILE="${REPO_ROOT}/k8s/base/dataset/create-table.sql"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: $1" >&2
    exit 1
  fi
}

require kubectl

if ! kubectl -n "${NAMESPACE}" get svc minio >/dev/null 2>&1; then
  echo "[ERROR] MinIO service not found in namespace ${NAMESPACE}" >&2
  exit 1
fi

if ! kubectl -n "${NAMESPACE}" get svc "${TRINO_SERVICE}" >/dev/null 2>&1; then
  echo "[ERROR] Trino service '${TRINO_SERVICE}' not found in namespace ${NAMESPACE}" >&2
  echo "[INFO] Available services:"
  kubectl -n "${NAMESPACE}" get svc
  exit 1
fi

echo "[INFO] Ensuring MinIO bucket '${SAMPLE_BUCKET}' exists"
MINIO_USER=$(kubectl -n "${NAMESPACE}" get secret minio-credentials -o jsonpath='{.data.rootUser}' | base64 -d)
MINIO_PASS=$(kubectl -n "${NAMESPACE}" get secret minio-credentials -o jsonpath='{.data.rootPassword}' | base64 -d)

kubectl -n "${NAMESPACE}" run minio-mc --rm -i --restart=Never \
  --image=minio/mc:RELEASE.2026-03-24T08-29-49Z \
  --env="MINIO_USER=${MINIO_USER}" \
  --env="MINIO_PASS=${MINIO_PASS}" \
  -- sh -c 'mc alias set local http://minio:9000 "${MINIO_USER}" "${MINIO_PASS}" >/dev/null && mc mb --ignore-existing "local/'"${SAMPLE_BUCKET}"'"'

echo "[INFO] Creating/updating SQL configmap"
kubectl -n "${NAMESPACE}" create configmap trino-sql-bootstrap \
  --from-file=create-schema.sql="${SQL_SCHEMA_FILE}" \
  --from-file=create-table.sql="${SQL_TABLE_FILE}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[INFO] Running Trino bootstrap pod"
kubectl -n "${NAMESPACE}" delete pod trino-bootstrap --ignore-not-found
cat <<POD | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: trino-bootstrap
  namespace: ${NAMESPACE}
spec:
  restartPolicy: Never
  containers:
    - name: trino-bootstrap
      image: trinodb/trino:476
      command:
        - sh
        - -c
        - |
          trino --server http://${TRINO_SERVICE}:${TRINO_PORT} --file /sql/create-schema.sql
          trino --server http://${TRINO_SERVICE}:${TRINO_PORT} --file /sql/create-table.sql
      volumeMounts:
        - name: sql
          mountPath: /sql
  volumes:
    - name: sql
      configMap:
        name: trino-sql-bootstrap
POD

kubectl -n "${NAMESPACE}" wait --for=jsonpath='{.status.phase}'=Succeeded pod/trino-bootstrap --timeout=300s
kubectl -n "${NAMESPACE}" logs trino-bootstrap
kubectl -n "${NAMESPACE}" delete pod trino-bootstrap --ignore-not-found

echo "[OK] Sample data bootstrap completed"

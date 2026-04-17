#!/usr/bin/env bash
set -euo pipefail

kubectl -n data-platform get pods
kubectl -n data-platform get svc minio
kubectl -n data-platform get trinoclusters.trino.stackable.tech trino
kubectl -n data-platform get hiveclusters.hive.stackable.tech hive-metastore

echo "[OK] Smoke test completed"

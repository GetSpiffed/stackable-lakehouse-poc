#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Checking Postgres deployment"
kubectl -n data-platform wait deployment/postgres --for=condition=Available --timeout=120s

echo "[INFO] Checking Stackable services"
kubectl -n data-platform wait HiveCluster/hive-metastore --for=condition=Available --timeout=300s
kubectl -n data-platform wait TrinoCluster/trino --for=condition=Available --timeout=300s

echo "[INFO] Current pod state"
kubectl -n data-platform get pods

echo "[OK] Smoke test completed"

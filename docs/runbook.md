# Runbook - Stackable Lakehouse PoC

Dit runbook volgt de bestaande opzet: **één base-set manifests** met environment overlays voor **local** en **IONOS**.

## Local end-to-end (één flow)

```bash
scripts/local/bootstrap-local.sh
```

Dit script doet achtereenvolgens:
1. k3d cluster maken/controleren.
2. Stackable operators installeren.
3. Trino + Hive Metastore + MinIO deployen met local overlay.
4. Smoke test draaien.
5. Sample schema + tabel laden in `hive.lakehouse.orders`.

## Handmatig per stap

### 1) Install Stackable operators

```bash
scripts/local/install-operators.sh
# of
scripts/ionos/install-operators.sh
```

Standaard gebruikt het script `STACKABLE_VERSION=26.3.0`.

### 2) Deploy Trino, Hive Metastore en MinIO

```bash
kubectl apply -k k8s/base/overlays/local
# of
kubectl apply -k k8s/base/overlays/ionos
```

### 3) Verificatie

```bash
scripts/local/smoke-test.sh
# of
scripts/ionos/smoke-test.sh
```

### 4) Sample data laden (local)

```bash
scripts/local/load-sample-data.sh
```

## Opmerkingen

- MinIO draait als singleton voor PoC-doeleinden.
- Hive Metastore draait in embedded Derby-mode (snel voor PoC, niet voor productie).
- Trino gebruikt de Hive catalog met MinIO als S3-endpoint.

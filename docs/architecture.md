# Architecture

## Overview

This PoC deploys a data lakehouse on Kubernetes using the [Stackable Data Platform](https://stackable.tech/).
All components run in the `data-platform` namespace. Stackable operators run in `stackable-operators`.

```
┌─────────────────────────────────────────────────────────┐
│  namespace: data-platform                               │
│                                                         │
│  ┌──────────┐    ┌────────────────┐    ┌─────────────┐ │
│  │  Trino   │───▶│ Hive Metastore │───▶│  Postgres   │ │
│  │ Cluster  │    │  (HMS)         │    │  (metadata) │ │
│  └────┬─────┘    └────────────────┘    └─────────────┘ │
│       │                                                 │
│       ▼                                                 │
│  ┌──────────┐    ┌────────────────┐                     │
│  │  MinIO   │◀───│  S3Connection  │                     │
│  │  (local) │    │  + S3Bucket    │                     │
│  └──────────┘    └────────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

## Components

| Component | Version | Role |
|---|---|---|
| Trino | 476 | Query engine |
| Hive Metastore | 3.1.3 | Table/schema catalog |
| Postgres | 16 | HMS metadata backend |
| MinIO | 2026-01-03 | Local S3-compatible object store |
| commons-operator | 26.3.0 | Installs S3Connection/S3Bucket CRDs |
| hive-operator | 26.3.0 | Manages HiveCluster CR |
| trino-operator | 26.3.0 | Manages TrinoCluster CR |
| secret-operator | 26.3.0 | Manages SecretClass credential injection |
| listener-operator | 26.3.0 | Manages service exposure |

## Data flow

1. **Query** — A client submits SQL to the Trino coordinator.
2. **Metadata** — Trino reads schema/table definitions from Hive Metastore (HMS).
3. **HMS ↔ Postgres** — HMS persists all metadata in Postgres (`metastore` database).
4. **Storage** — Trino reads/writes Parquet files directly from MinIO (local) or IONOS S3 (production) using the credentials configured in `TrinoCatalog`.

## S3 credentials approach

The base layer configures TrinoCatalog with inline S3 credentials (pointing to MinIO).
The IONOS overlay patches the TrinoCatalog to use IONOS S3 via a strategic merge patch
(`overlays/ionos/patches-catalog.yaml`).

The `S3Connection` and `S3Bucket` CRDs are also deployed, wired to MinIO via a `SecretClass`
(`minio-s3-credentials`). These can be used as the authoritative S3 reference once operators
fully support the `s3.reference` field in TrinoCatalog.

## Overlays

| Overlay | Storage class | S3 backend |
|---|---|---|
| `local` | default (k3d) | In-cluster MinIO |
| `ionos` | `ionos-enterprise-hdd` | IONOS S3 (external) |

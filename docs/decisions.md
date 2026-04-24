# Architecture Decision Records

## ADR-001: Stackable Data Platform as operator framework

**Decision**: Use Stackable operators (hive-operator, trino-operator) instead of plain Helm charts.

**Rationale**: Stackable provides CRD-based lifecycle management for Hive and Trino, including
auto-configuration of inter-component connectivity. This reduces YAML boilerplate and makes
upgrades operator-driven rather than manual.

**Trade-off**: Stackable operators are less widely known than vanilla Helm charts. Debugging
requires familiarity with Stackable CRDs in addition to the underlying products.

---

## ADR-002: Postgres as Hive Metastore backend

**Decision**: Use Postgres 16 instead of the embedded Derby database.

**Rationale**: Derby in `/tmp` loses all metadata on pod restart, making the metastore
effectively stateless. Postgres survives restarts and is required for any multi-replica
or durable setup.

**Trade-off**: Adds a Postgres deployment to maintain. For a fully throwaway local dev
environment, Derby would be simpler — but it is unsuitable even for light repeated use.

---

## ADR-003: kustomize base + overlays for multi-environment

**Decision**: Use a single kustomize base with `local` and `ionos` overlays.

**Rationale**: The two environments share most configuration (same Trino version, same
Hive Metastore, same namespace structure) and differ only in storage class, resource
limits, and S3 backend. Overlays minimize duplication without a full Helm chart.

**Trade-off**: Resources cannot easily be excluded per overlay. MinIO is included in
the IONOS overlay even though IONOS uses external S3. A future refactor could split
the base into `base-common` and `base-minio`.

---

## ADR-004: S3Connection/S3Bucket CRDs alongside inline TrinoCatalog config

**Decision**: Deploy `S3Connection` (minio) and `S3Bucket` (lakehouse) CRDs, but keep
the TrinoCatalog using inline S3 credentials for now.

**Rationale**: The Stackable `TrinoCatalog` operator currently requires a `SecretClass`
to use `s3.reference`. The SecretClass + secret-operator wiring is in place
(`minio-s3-credentials` SecretClass, labeled `minio-credentials` Secret). Switching
TrinoCatalog to `s3.reference: lakehouse` is a one-line change once this is verified.

**Trade-off**: Two parallel S3 credential paths exist temporarily (inline in TrinoCatalog
and via S3Connection). This should be consolidated once the reference path is validated.

---

## ADR-005: Stackable operators in dedicated namespace

**Decision**: Install Stackable Helm releases into the `stackable-operators` namespace.

**Rationale**: Operators are cluster-wide controllers; co-locating them with workloads
in `data-platform` muddies namespace boundaries and complicates RBAC.

**Trade-off**: Helm status checks must always pass `--namespace stackable-operators`.

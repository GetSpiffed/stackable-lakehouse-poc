# Stackable Lakehouse PoC

Deze repository bevat een **portable Lakehouse Proof of Concept (PoC)** op Kubernetes, gebouwd met de Stackable Data Platform operators.

Het doel van dit project is:
- dezelfde functionele stack lokaal en in de cloud draaien met minimale verschillen;
- een klein maar compleet dataplatform aanbieden voor experimenten;
- deployments voorspelbaar maken via één gedeelde `base` en environment-specifieke overlays.

De PoC bestaat uit:
- **Trino** als SQL query engine;
- **Hive Metastore** als metadata-laag;
- **MinIO (S3-compatible)** als object storage voor tabellen/data;
- **Stackable operators** om de lifecycle van de bovenstaande componenten op Kubernetes te beheren.

---

## Architectuur in het kort

### Kubernetes layout
- Alle workloads draaien in namespace `data-platform`.
- Stackable operators worden via Helm geïnstalleerd (commons, secret, listener, hive, trino).
- Workloads worden uitgerold met Kustomize overlays:
  - `k8s/base/overlays/local` voor lokale ontwikkeling;
  - `k8s/base/overlays/ionos` voor IONOS Kubernetes.

### Datastroom
1. Trino leest/schrijft tabellen via de Hive connector.
2. Hive Metastore beheert schema- en tabelmetadata.
3. Data-bestanden landen in MinIO (`S3 endpoint`).
4. Voor de lokale flow wordt voorbeelddata geladen in `hive.lakehouse.orders`.

### Belangrijke PoC-keuzes
- MinIO draait als singleton (één replica), bedoeld voor demo/test.
- Hive Metastore gebruikt embedded Derby (snel voor PoC, niet voor productie).
- Eén gedeelde base met overlays maakt lokaal ↔ cloud wisselen eenvoudig.

---

## Repository-structuur

```text
stackable-lakehouse-poc/
├─ README.md
├─ docs/
│  ├─ runbook.md
│  ├─ architecture.md
│  └─ decisions.md
├─ k8s/
│  └─ base/
│     ├─ namespaces/
│     ├─ operators/
│     ├─ storage/
│     ├─ hive/
│     ├─ trino/
│     ├─ dataset/
│     └─ overlays/
│        ├─ local/
│        └─ ionos/
└─ scripts/
   ├─ local/
   └─ ionos/
```

---

## Vereisten

### Algemene tooling
Installeer lokaal (of in je CI runner) minimaal:
- `kubectl`
- `helm`
- `kustomize` (of `kubectl apply -k` ondersteuning)
- `docker` (voor lokale k3d workflow)

### Voor lokale uitrol
- `k3d`
- voldoende resources (advies):
  - 16 GB RAM (32 GB comfortabel)
  - 4+ vCPU
  - 20+ GB vrije disk

### Voor IONOS uitrol
- toegang tot een werkend IONOS Managed Kubernetes cluster;
- een geldige `kubeconfig` context gericht op dat cluster;
- een beschikbare StorageClass met naam `ionos-enterprise-hdd` (zoals gebruikt in de IONOS overlay), of een aangepaste patch als je een andere StorageClass gebruikt.

---

## Lokaal uitrollen (k3d)

Je hebt twee opties: volledig geautomatiseerd of stap-voor-stap.

## Optie A — end-to-end script (aanbevolen)

```bash
scripts/local/bootstrap-local.sh
```

Dit script voert achtereenvolgens uit:
1. k3d cluster aanmaken/controleren;
2. Stackable operators installeren/upgraden;
3. deployment van Trino + Hive + MinIO via local overlay;
4. smoke test;
5. bootstrap van schema + voorbeeldtabel in Trino.

## Optie B — handmatig per stap

### 1) Cluster aanmaken

```bash
scripts/local/create-k3d-cluster.sh
```

Optionele variabelen:
- `CLUSTER_NAME` (default `stackable-poc`)
- `K3D_SERVERS` (default `1`)
- `K3D_AGENTS` (default `1`)
- `K3D_WAIT` (default `true`)

Voorbeeld:

```bash
CLUSTER_NAME=stackable-poc K3D_SERVERS=1 K3D_AGENTS=1 scripts/local/create-k3d-cluster.sh
```

### 2) Operators installeren

```bash
scripts/local/install-operators.sh
```

Optionele variabele:
- `STACKABLE_VERSION` (default `26.3.0`)

Voorbeeld:

```bash
STACKABLE_VERSION=26.3.0 scripts/local/install-operators.sh
```

### 3) Workloads deployen

```bash
kubectl apply -k k8s/base/overlays/local
```

### 4) Controleren of alles draait

```bash
scripts/local/smoke-test.sh
kubectl -n data-platform get pods
```

### 5) Voorbeelddata laden

```bash
scripts/local/load-sample-data.sh
```

Hiermee wordt o.a. bucket `lakehouse` aangemaakt en SQL bootstrap uitgevoerd met:
- `k8s/base/dataset/create-schema.sql`
- `k8s/base/dataset/create-table.sql`

### 6) Optioneel: Trino benaderen vanaf je laptop

```bash
kubectl -n data-platform port-forward svc/trino-coordinator-default 8080:8080
```

Daarna kun je lokaal queries uitvoeren tegen `http://localhost:8080`.

---

## Uitrollen naar IONOS Kubernetes

Onderstaande stappen gaan uit van een bestaande IONOS cluster-context in je `kubeconfig`.

### 1) Verifieer context

```bash
kubectl config get-contexts
kubectl config current-context
kubectl get nodes
```

Zorg dat je **niet** per ongeluk op je lokale k3d-context zit.

### 2) Controleer StorageClass

De IONOS overlay zet voor de MinIO PVC:
- `storageClassName: ionos-enterprise-hdd`

Controleer of deze bestaat:

```bash
kubectl get storageclass
```

Als jouw cluster een andere StorageClass gebruikt, pas dan `k8s/base/overlays/ionos/patches-storage.yaml` aan.

### 3) Installeer Stackable operators

```bash
scripts/ionos/install-operators.sh
```

Ook hier kun je `STACKABLE_VERSION` overriden indien nodig.

### 4) Deploy de IONOS overlay

```bash
kubectl apply -k k8s/base/overlays/ionos
```

### 5) Controleer de deployment

```bash
scripts/ionos/smoke-test.sh
kubectl -n data-platform get pods
kubectl -n data-platform get pvc
```

### 6) (Optioneel) Ook sample data laden in IONOS

Als je dezelfde demo-data wilt gebruiken als lokaal, kun je hetzelfde script gebruiken:

```bash
scripts/local/load-sample-data.sh
```

Let op: dit script verwacht standaard namespace `data-platform` en Trino service `trino-coordinator-default`.

---

## Veelgebruikte operationele commando’s

### Herdeploy van een overlay

```bash
kubectl apply -k k8s/base/overlays/local
# of
kubectl apply -k k8s/base/overlays/ionos
```

### Status check

```bash
kubectl -n data-platform get all
kubectl -n data-platform get trinoclusters.trino.stackable.tech
kubectl -n data-platform get hiveclusters.hive.stackable.tech
```

### Logs inspecteren

```bash
kubectl -n data-platform logs deploy/minio
kubectl -n data-platform get pods
kubectl -n data-platform logs <pod-naam>
```

---

## Troubleshooting

### Operators komen niet op
- Controleer Helm releases:
  ```bash
  helm list
  ```
- Installeer/upgrad nogmaals:
  ```bash
  scripts/local/install-operators.sh
  # of
  scripts/ionos/install-operators.sh
  ```

### MinIO PVC blijft `Pending`
- Controleer StorageClass en beschikbaarheid van volumes:
  ```bash
  kubectl get storageclass
  kubectl -n data-platform describe pvc minio-data
  ```

### Trino service ontbreekt
- Bekijk services in namespace:
  ```bash
  kubectl -n data-platform get svc
  ```
- Controleer of `TrinoCluster` resource `trino` aanwezig is.

### Sample data script faalt
- Controleer of `svc/minio` en `svc/trino-coordinator-default` bestaan.
- Controleer pod logs van `trino-bootstrap`:
  ```bash
  kubectl -n data-platform logs trino-bootstrap
  ```

---

## Productie-opmerking

Deze repository is bewust een PoC: klein, leerzaam en makkelijk te reproduceren.
Voor productie zijn minimaal extra maatregelen nodig rond:
- high availability;
- back-ups en disaster recovery;
- secrets management;
- observability/alerting;
- security hardening en netwerkbeleid;
- schaal- en performance-tuning.

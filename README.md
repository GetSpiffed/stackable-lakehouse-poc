# Stackable Lakehouse PoC

This repository contains a minimal, portable Proof of Concept (PoC) for running a data platform using Stackable on Kubernetes.

The goal is to run the same setup locally (via k3d) and in a cloud environment (e.g. IONOS) with minimal differences.

---

## Prerequisites

Before you start, make sure your local environment is set up with the following tools. This PoC runs on a local Kubernetes cluster using k3d (Kubernetes in Docker).

### 1. Hardware Requirements

Recommended minimum:

- 16 GB RAM (32 GB recommended)
- 4+ CPU cores
- 20+ GB free disk space

---

### 2. Required Software

Install the following tools:

#### Docker Desktop

- Install Docker Desktop (with WSL2 backend enabled)
- Allocate sufficient resources:
  - Memory: 16–20 GB
  - CPU: 4–6 cores

Verify installation:

```bash
docker version
docker info
```

---

#### WSL2 (Windows only)

Ensure WSL2 is installed and working:

```bash
wsl --status
wsl -l -v
```

You should have at least one Linux distribution installed (e.g. Ubuntu).

---

#### kubectl

Kubernetes CLI tool:

```bash
kubectl version --client
```

---

#### k3d

Local Kubernetes cluster in Docker:

```bash
k3d version
```

---

#### Helm

Kubernetes package manager:

```bash
helm version
```

---

### 3. Verify Setup

Once everything is installed, you should be able to:

```bash
k3d cluster create test
kubectl get nodes
```

Expected output should show a node in `Ready` state.

You can delete the test cluster afterwards:

```bash
k3d cluster delete test
```

---

## Quick Start

Create a local Kubernetes cluster:

```bash
k3d cluster create stackable-poc
kubectl get nodes
```

Deploy the base resources:

```bash
scripts/local/bootstrap-local.sh
# of handmatig:
scripts/local/install-operators.sh
kubectl apply -k k8s/base/overlays/local
```

Verify namespace:

```bash
kubectl get namespaces
```

---

## Project Structure

```text
stackable-portable-poc/
├─ README.md
├─ scripts/
│  └─ local/
├─ k8s/
│  ├─ base/
│  └─ overlays/
```

- `base/`: shared Kubernetes resources
- `overlays/local/`: local-specific configuration
- `overlays/ionos/`: cloud-specific configuration

---

## Notes

- Make sure Docker Desktop is running before creating a cluster
- If you are on a corporate laptop, WSL2 or Docker may be restricted by policy
- Keep the PoC minimal: Trino + Hive Metastore + S3-compatible storage

---

## Troubleshooting

### Docker not working

Check:

```bash
docker version
```

Restart Docker Desktop if needed.

---

### WSL issues (Windows)

Check:

```bash
wsl --status
wsl -l -v
```

If no distributions are installed:

```bash
wsl --install -d Ubuntu
```

---

### k3d cluster fails

Ensure:

- Docker is running
- Enough memory is allocated

Delete and recreate cluster:

```bash
k3d cluster delete stackable-poc
k3d cluster create stackable-poc
```

---

## Next Steps

- Install Stackable operators (scripts/local/install-operators.sh of scripts/ionos/install-operators.sh)
- Deploy Trino, Hive Metastore, and MinIO (kubectl apply -k k8s/base/overlays/<env>)
- Load sample dataset (scripts/local/load-sample-data.sh)
- Run first queries


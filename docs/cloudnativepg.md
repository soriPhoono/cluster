# CloudNativePG

**Status:** Planned — **not** present in `k3s/` yet\
**Scope:** PostgreSQL clusters managed by the **CloudNativePG** operator.

## Goals

- Install the **CloudNativePG** operator via Flux (Helm or plain manifests).
- Define `Cluster` (or `ScheduledBackup`) resources for application databases, with backups and storage classes aligned to your homelab storage (for example Longhorn or local-path).

## GitOps paths

None yet. When implemented, expect:

- Operator install under `k3s/infrastructure/controllers/` or a dedicated `k3s/apps/postgres/` path referenced by a Flux `Kustomization`.
- Instance CRs and sealed secrets for superuser credentials in a namespace dedicated to databases.

## Upstream

- [CloudNativePG documentation](https://cloudnative-pg.io/documentation/current/)
- [CloudNativePG GitHub](https://github.com/cloudnative-pg/cloudnative-pg)

# VMStack (monitoring and observability)

**Status:** Planned - **not** present in `k3s/` yet

**Scope:** Deploy a **VMStack**-based observability platform (VictoriaMetrics ecosystem) for metrics, scraping, alerting, and dashboards across cluster infrastructure and workloads.

## Goals

- Establish durable cluster monitoring before database and identity platform rollout.
- Collect infrastructure metrics (nodes, Kubernetes control plane, Cilium/Envoy/Cloudflare operator where available).
- Provide alerting for saturation, availability, and certificate/network failures.
- Standardize dashboards and SLO-oriented views for homelab services.

## Prerequisites and assumptions

- StorageClass and retention targets are defined for metrics/alert data.
- Ingress exposure plan exists for dashboards and alertmanager endpoints (internal-first preferred).
- Auth strategy is aligned with future Authentik integration (initial local auth acceptable in testing).
- Backup policy for monitoring configuration (rules, dashboards, scrape config) is documented.

## Proposed GitOps layout

When implemented, place manifests under infra controllers:

- `k3s/infrastructure/controllers/observability/vmstack/vmstack.yaml` - HelmRepository + HelmRelease.
- `k3s/infrastructure/controllers/observability/vmstack/kustomization.yaml` - wrapper.
- `k3s/infrastructure/controllers/observability/vmstack/rules/` - alert rules and recording rules.
- `k3s/infrastructure/controllers/observability/vmstack/dashboards/` - dashboard config maps/manifests.
- `k3s/infrastructure/testing/kustomization.yaml` - include the observability controller path.

## Implementation plan (phased)

1. **Monitoring baseline design**

   - Define retention and resource budgets (CPU/memory/storage) for testing and prod.
   - Select scrape targets and label taxonomy (cluster, env, component, service).
   - Define critical alerts (node down, API unavailable, certificate expiry, ingress failure, DNS/tunnel errors).

1. **Deploy VMStack in testing**

   - Add Helm source/release with persistent storage and conservative limits.
   - Enable kube-state-metrics / node-exporter equivalents and Kubernetes component scraping.
   - Confirm ingestion and query performance at expected sample rates.

1. **Integrate platform components**

   - Add scrape jobs for Envoy Gateway, cert-manager, Cloudflare operator, and (later) Cilium.
   - Add cluster-specific rules for tunnel availability and ingress health.
   - Build starter dashboards for cluster health, traffic, and certificate lifecycle.

1. **Alerting and notification hardening**

   - Configure Alertmanager routing and notification channels.
   - Tune thresholds to reduce false positives in homelab burst conditions.
   - Add runbook links in alert annotations.

1. **Production promotion**

   - Promote tested values and rule sets into production paths.
   - Re-validate retention/storage headroom with production sample volume.
   - Lock version pinning and upgrade cadence with rollback notes.

## Validation checklist

- VMStack components are healthy and persistent volumes are bound.
- Core Kubernetes/node metrics are present and queryable.
- Key dashboards load with expected series cardinality.
- Test alerts fire and resolve correctly through notification routes.
- Resource use remains within defined budgets after 24h+ soak.

## Risks and rollback

- **Primary risk:** high-cardinality metrics causing cost/performance degradation.
- **Mitigation:** strict scrape/label controls, retention limits, and staged target onboarding.
- **Rollback approach:** revert Flux commit for observability manifests and reconcile; preserve previous rules/dashboards snapshots in Git for rapid restore.

## Upstream

- [VictoriaMetrics documentation](https://docs.victoriametrics.com/)
- [VictoriaMetrics Operator documentation](https://docs.victoriametrics.com/operator/)
- [VictoriaMetrics Helm charts](https://github.com/VictoriaMetrics/helm-charts)

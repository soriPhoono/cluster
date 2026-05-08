# cert-manager

**Status:** Deployed
**Scope:** TLS certificate automation via the cert-manager Helm release.

## GitOps paths

| Resource | Path |
| --- | --- |
| HelmRepository + HelmRelease | [`../k3s/infrastructure/controllers/network/cert-manager/cert-manager.yaml`](../k3s/infrastructure/controllers/network/cert-manager/cert-manager.yaml) |
| Controller wrapper | [`../k3s/infrastructure/controllers/network/cert-manager/kustomization.yaml`](../k3s/infrastructure/controllers/network/cert-manager/kustomization.yaml) |

## Behavior in this cluster

- CRDs are installed and kept on upgrade (`crds.enabled`, `crds.keep` in values).
- **ClusterIssuer** / **Certificate** resources for DNS-01, HTTP-01, or internal CAs are not committed yet; add them under `k3s/infrastructure/testing/suplemental` (or another Flux-managed path) when you define issuers.

## Upstream

- [cert-manager documentation](https://cert-manager.io/docs/)
- [Installing on Kubernetes](https://cert-manager.io/docs/installation/kubernetes/)

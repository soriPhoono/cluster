# cert-manager

**Status:** Deployed
**Scope:** TLS certificate automation via the cert-manager Helm release.

## GitOps paths

| Resource | Path |
| --- | --- |
| HelmRelease | [`../k3s/infrastructure/controllers/cert-manager.yaml`](../k3s/infrastructure/controllers/cert-manager.yaml) |
| HelmRepository source | [`../k3s/infrastructure/controllers/source/cert-manager.yaml`](../k3s/infrastructure/controllers/source/cert-manager.yaml) |

## Behavior in this cluster

- CRDs are installed and kept on upgrade (`crds.enabled`, `crds.keep` in values).
- **ClusterIssuer** / **Certificate** resources for DNS-01, HTTP-01, or internal CAs are not committed yet; add them under `k3s/infrastructure/configs` (or another Flux-managed path) when you define issuers.

## Upstream

- [cert-manager documentation](https://cert-manager.io/docs/)
- [Installing on Kubernetes](https://cert-manager.io/docs/installation/kubernetes/)

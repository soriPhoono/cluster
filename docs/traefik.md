# Traefik

**Status:** Deployed
**Scope:** Cluster ingress and Traefik dashboard settings owned by this repo.

## GitOps paths

| Resource | Path |
| --- | --- |
| HelmRelease | [`../k3s/infrastructure/controllers/traefik/traefik.yaml`](../k3s/infrastructure/controllers/traefik/traefik.yaml) |
| Kustomize wrapper | [`../k3s/infrastructure/controllers/traefik/kustomization.yaml`](../k3s/infrastructure/controllers/traefik/kustomization.yaml) |
| HelmRepository source | [`../k3s/infrastructure/controllers/source/traefik.yaml`](../k3s/infrastructure/controllers/source/traefik.yaml) |

## Behavior in this cluster

- **k3s** is installed with bundled Traefik **disabled** so this Helm-managed Traefik is the ingress controller (see `--disable=traefik` in [`../flake.nix`](../flake.nix) `k3d cluster create` arguments).
- The Helm chart enables the **IngressRoute dashboard** (`ingressRoute.dashboard.enabled: true`).
- **Published service** for Ingress status is enabled (`providers.kubernetesIngress.publishedService.enabled: true`) so external-dns or LB integrations can resolve the ingress hostname correctly when configured.

Add `Ingress`, `IngressRoute`, or middleware manifests under [`../k3s/infrastructure/configs`](../k3s/infrastructure/configs) when you introduce them, and enable the `infra-configs` `Kustomization` in [`../k3s/clusters/testing/infrastructure.yaml`](../k3s/clusters/testing/infrastructure.yaml).

## Upstream

- [Traefik documentation](https://doc.traefik.io/traefik/)
- [Traefik Helm chart](https://github.com/traefik/traefik-helm-chart)

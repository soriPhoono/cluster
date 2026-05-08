# Traefik

**Status:** Deployed
**Scope:** Cluster ingress and Traefik dashboard settings owned by this repo.

## GitOps paths

| Resource | Path |
| --- | --- |
| HelmRepository + HelmRelease | [`../k3s/infrastructure/controllers/core/traefik.yaml`](../k3s/infrastructure/controllers/core/traefik.yaml) |
| Testing infra aggregator | [`../k3s/infrastructure/testing/kustomization.yaml`](../k3s/infrastructure/testing/kustomization.yaml) |
| Testing cluster infra kustomizations | [`../k3s/clusters/testing/infra.yaml`](../k3s/clusters/testing/infra.yaml) |

## Behavior in this cluster

- **k3s** is installed with bundled Traefik **disabled** so this Helm-managed Traefik is the ingress controller (see `--disable=traefik` in [`../flake.nix`](../flake.nix) `k3d cluster create` arguments).
- **k3s servicelb** is disabled (see `--disable=servicelb` in [`../flake.nix`](../flake.nix)). `LoadBalancer` IPs are assigned by **Cilium LB IPAM** and advertised with **Cilium BGP** (see [cilium.md](cilium.md)); there is no in-cluster ServiceLB or MetalLB.
- The Helm chart enables the **IngressRoute dashboard** (`ingressRoute.dashboard.enabled: true`).
- **Published service** for Ingress status is enabled (`providers.kubernetesIngress.publishedService.enabled: true`) so external-dns or LB integrations can resolve the ingress hostname correctly when configured.
- Traefik `LoadBalancer` IP allocation (when the service type is used) comes from the **Cilium** pool in [`../k3s/infrastructure/controllers/network/cilium/bgp/loadbalancer-ip-pool.yaml`](../k3s/infrastructure/controllers/network/cilium/bgp/loadbalancer-ip-pool.yaml); optional annotations can target a specific pool via Cilium’s service selectors (see Cilium LB IPAM docs).

App and tunnel resources for testing are reconciled from the `apps-testing` and `infra-suplemental` Flux kustomizations defined in [`../k3s/clusters/testing/kustomization.yaml`](../k3s/clusters/testing/kustomization.yaml).

## Upstream

- [Traefik documentation](https://doc.traefik.io/traefik/)
- [Traefik Helm chart](https://github.com/traefik/traefik-helm-chart)

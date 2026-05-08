# MetalLB

**Status:** Deployed  
**Scope:** Service `LoadBalancer` IP assignment for the testing cluster.

## GitOps paths

| Resource | Path |
| --- | --- |
| MetalLB Helm source + release | [`../k3s/infrastructure/controllers/network/metallb/metallb.yaml`](../k3s/infrastructure/controllers/network/metallb/metallb.yaml) |
| MetalLB controller wrapper | [`../k3s/infrastructure/controllers/network/metallb/kustomization.yaml`](../k3s/infrastructure/controllers/network/metallb/kustomization.yaml) |
| Testing infra aggregator | [`../k3s/infrastructure/testing/kustomization.yaml`](../k3s/infrastructure/testing/kustomization.yaml) |
| Pool + L2 advertisement | [`../k3s/infrastructure/testing/suplemental/metallb-pools.yaml`](../k3s/infrastructure/testing/suplemental/metallb-pools.yaml) |
| Supplemental wrapper | [`../k3s/infrastructure/testing/suplemental/kustomization.yaml`](../k3s/infrastructure/testing/suplemental/kustomization.yaml) |

## Behavior in this cluster

- The testing k3d network is currently `172.18.0.0/16`.
- MetalLB allocates external service IPs from `172.18.255.200-172.18.255.250`.
- `L2Advertisement` `default-l2` announces addresses from `default-pool`.
- Traefik is annotated to use this pool, keeping ingress allocation deterministic.
- Cloudflare tunnel routing remains available; MetalLB adds direct `LoadBalancer` service IP support.

## Verification

- `kubectl -n metallb-system get pods`
- `kubectl get ipaddresspools -A`
- `kubectl get l2advertisements -A`
- `kubectl -n traefik get svc traefik -o wide`

## Upstream

- [MetalLB documentation](https://metallb.io/)
- [MetalLB Helm chart](https://artifacthub.io/packages/helm/metallb/metallb)

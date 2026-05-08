# Cilium Service Layer

**Status:** Deployed\
**Scope:** CNI + Service `LoadBalancer` IP assignment for the testing cluster.

## GitOps paths

| Resource | Path |
| --- | --- |
| Cilium Helm source + release | [`../k3s/infrastructure/controllers/network/cilium/cilium.yaml`](../k3s/infrastructure/controllers/network/cilium/cilium.yaml) |
| Cilium controller wrapper | [`../k3s/infrastructure/controllers/network/cilium/kustomization.yaml`](../k3s/infrastructure/controllers/network/cilium/kustomization.yaml) |
| Testing infra aggregator | [`../k3s/infrastructure/testing/kustomization.yaml`](../k3s/infrastructure/testing/kustomization.yaml) |
| Pool + L2 announcement | [`../k3s/infrastructure/testing/suplemental/cilium-loadbalancer-pool.yaml`](../k3s/infrastructure/testing/suplemental/cilium-loadbalancer-pool.yaml) |
| Supplemental wrapper | [`../k3s/infrastructure/testing/suplemental/kustomization.yaml`](../k3s/infrastructure/testing/suplemental/kustomization.yaml) |

## Behavior in this cluster

- The testing k3d network is currently `172.18.0.0/16`.
- Cilium allocates external service IPs from `172.18.255.200-172.18.255.250`.
- `CiliumL2AnnouncementPolicy` `default-l2` announces addresses from `CiliumLoadBalancerIPPool` `default-pool`.
- Cloudflare tunnel routing remains available; Cilium also provides direct `LoadBalancer` service IP support.

## Verification

- `kubectl -n kube-system get pods -l k8s-app=cilium`
- `kubectl get ciliumloadbalancerippools`
- `kubectl get ciliuml2announcementpolicies`
- `kubectl get svc -A | rg LoadBalancer`

## Upstream

- [Cilium documentation](https://docs.cilium.io/)
- [Cilium Helm chart](https://artifacthub.io/packages/helm/cilium/cilium)

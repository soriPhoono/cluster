# Cilium (full k3s network stack + eBGP)

**Status:** **Deployed** — Cilium replaces **Flannel** (CNI), **k3s ServiceLB** (disabled at install), and **MetalLB**. Pod networking, **LoadBalancer IPAM**, and **eBGP** advertisement of Pod CIDRs plus `LoadBalancer` VIPs are owned by Cilium.

**Scope:** Single network data plane: Cilium CNI + LB IPAM + BGP control plane toward upstream routers (eBGP). kube-proxy remains enabled (`kubeProxyReplacement: "false"`) until you deliberately move to kube-proxy-free mode.

## What Cilium replaces

| Former component | Replacement |
| --- | --- |
| Flannel | Cilium CNI (tunnel datapath, Kubernetes IPAM) |
| k3s ServiceLB (`klipper-lb`) | Disabled in `k3d`/`k3s` args; no in-cluster LB shim |
| MetalLB | **CiliumLoadBalancerIPPool** + **Cilium BGP** advertisement of `LoadBalancerIP` |

## GitOps layout

| Resource | Path |
| --- | --- |
| HelmRepository + HelmRelease | [`../k3s/infrastructure/controllers/network/cilium/cilium.yaml`](../k3s/infrastructure/controllers/network/cilium/cilium.yaml) |
| Kustomize wrapper | [`../k3s/infrastructure/controllers/network/cilium/kustomization.yaml`](../k3s/infrastructure/controllers/network/cilium/kustomization.yaml) |
| LB pool + BGP CRs | [`../k3s/infrastructure/controllers/network/cilium/bgp/`](../k3s/infrastructure/controllers/network/cilium/bgp/) |
| Flux: CNI before rest of infra | [`../k3s/clusters/testing/infra.yaml`](../k3s/clusters/testing/infra.yaml) — `infra-cilium` first; `infra` and Cloudflare operator depend on it |

Cilium is applied only via **`infra-cilium`**, not duplicated under [`../k3s/infrastructure/testing/kustomization.yaml`](../k3s/infrastructure/testing/kustomization.yaml).

## Helm values (testing baseline)

- `ipam.mode: kubernetes` — per-node `podCIDR` from Kubernetes (k3s defaults).
- `routingMode: tunnel` — overlay between nodes.
- `kubeProxyReplacement: "false"` — keep k3s kube-proxy unless you migrate.
- `enableLBIPAM: true`, `defaultLBServiceIPAM: lbipam` — Cilium assigns `LoadBalancer` `.status.ingress[].ip` from pools.
- `bgpControlPlane.enabled: true` — `CiliumBGPClusterConfig` / `CiliumBGPPeerConfig` / `CiliumBGPAdvertisement` take effect.

## BGP and pools (homelab)

Under `bgp/`:

- **`CiliumLoadBalancerIPPool`** `default-lb-pool` — same range as the old MetalLB pool for k3d (`172.18.255.200–172.18.255.250` on `172.18.0.0/16`). **Change** `spec.blocks` for production to your routable service range.
- **`CiliumBGPClusterConfig`** `homelab-ebgp` — eBGP template: `localASN: 64512`, `peerASN: 64496`, `peerAddress: 192.0.2.1` (RFC 5737 TEST-NET-1 placeholder). **Replace** `peerAddress` and ASNs with your router; until then, k3d still gets LB IPs locally while BGP sessions stay idle or retry.
- **`CiliumBGPPeerConfig`** / **`CiliumBGPAdvertisement`** — IPv4 unicast; advertises **PodCIDR** per node and **LoadBalancerIP** for all services (sentinel `NotIn` selector). Tighten selectors if you should not leak VIPs to the fabric.

Optional: add a second peer, MD5 secret (`authSecretRef`), or `ebgpMultihop` in `CiliumBGPPeerConfig` per [Cilium BGP configuration](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-configuration.html).

## k3d / `nix run`

[`../flake.nix`](../flake.nix) creates the cluster with **`--disable=servicelb`**, **`--flannel-backend=none`**, **`--disable-network-policy`**, then **Helm-installs Cilium** (matching values) before Flux so the API server and Flux have pod networking. Chart version: `CILIUM_CHART_VERSION` in the flake and `spec.chart.spec.version` in the `HelmRelease` must stay aligned.

## Production k3s

Server/agent flags should mirror testing:

- `--disable=servicelb` (or equivalent: no ServiceLB)
- `--flannel-backend=none`
- `--disable-network-policy`

Install Cilium before application workloads; use the same Flux paths. Tune **`CiliumLoadBalancerIPPool`** and **`CiliumBGPClusterConfig`** for your LAN and ASN plan.

## Validation

- `cilium status` — agents and operator healthy.
- `kubectl get ippools` (short name for `CiliumLoadBalancerIPPool`) — pool not `Conflicting`, IPs available.
- `cilium bgp peers` (via CLI) or operator logs — eBGP `Established` after you set a real `peerAddress`.
- `LoadBalancer` services receive an external IP from the pool; `/32` (or `/128`) routes appear on the upstream router when BGP is up.

## Risks and rollback

- **Risk:** CNI/LB/BGP misconfiguration breaks reachability.
- **Mitigation:** staged rollout, router-side neighbor limits (ECMP), documented AS/path policy.
- **Rollback:** revert Git to the previous networking commit and reconcile; keep a known-good revision tagged.

## Upstream

- [Cilium documentation](https://docs.cilium.io/)
- [BGP control plane configuration](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-configuration.html)
- [LoadBalancer IPAM (LB IPAM)](https://docs.cilium.io/en/stable/network/lb-ipam/)
- [Kubernetes installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

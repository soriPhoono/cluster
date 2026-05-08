# Cilium (eBGP networking)

**Status:** **Phase 1 deployed** — Cilium is the cluster CNI with conservative defaults (tunnel datapath, Kubernetes IPAM, kube-proxy left enabled, **BGP control plane off**). BGP CRDs and homelab peer config are reserved for phase 2 under `k3s/infrastructure/controllers/network/cilium/bgp/`.

**Scope:** **Cilium** as the cluster CNI; **BGP control plane (eBGP)** for routable service IP advertisement is planned next (see rollout below).

## Goals

- Replace/standardize cluster networking on Cilium with kube-proxy replacement enabled where supported.
- Use Cilium BGP control plane to advertise service VIPs/LB ranges toward upstream router peers.
- Keep ingress exposure predictable for Envoy Gateway and future services while reducing ad-hoc L2 behavior.
- Establish a network-policy baseline (`default-deny` + explicit allow rules) after migration stability.

## GitOps layout

| Resource | Path |
| --- | --- |
| HelmRepository + HelmRelease | [`../k3s/infrastructure/controllers/network/cilium/cilium.yaml`](../k3s/infrastructure/controllers/network/cilium/cilium.yaml) |
| Kustomize wrapper | [`../k3s/infrastructure/controllers/network/cilium/kustomization.yaml`](../k3s/infrastructure/controllers/network/cilium/kustomization.yaml) |
| BGP manifests (phase 2) | [`../k3s/infrastructure/controllers/network/cilium/bgp/`](../k3s/infrastructure/controllers/network/cilium/bgp/) (placeholder; add `CiliumBGPClusterConfig`, `CiliumBGPPeerConfig`, advertisements, pools when enabling BGP) |
| Flux: CNI before rest of infra | [`../k3s/clusters/testing/infra.yaml`](../k3s/clusters/testing/infra.yaml) — `infra-cilium` applies `./k3s/infrastructure/controllers/network/cilium` first; `infra` and the Cloudflare operator `Kustomization` depend on it |

Cilium is **not** listed under [`../k3s/infrastructure/testing/kustomization.yaml`](../k3s/infrastructure/testing/kustomization.yaml) so it is not reconciled twice; the dedicated `infra-cilium` Flux `Kustomization` enforces ordering before MetalLB, cert-manager, Envoy Gateway, and the remote Cloudflare install.

## k3d / `nix run` bootstrap

The testing cluster is created **without Flannel** and **without** the built-in k3s network policy controller (Cilium provides policy). The deploy app in [`../flake.nix`](../flake.nix) installs Cilium with Helm **after** `k3d cluster create` and **before** Flux bootstrap so the control plane and Flux pods have pod networking.

Keep chart version in sync: `CILIUM_CHART_VERSION` in `flake.nix` and `spec.chart.spec.version` in the Cilium `HelmRelease`.

## Production k3s

Install servers/agents with an equivalent of:

- `--flannel-backend=none`
- `--disable-network-policy`

Bring up Cilium (Helm or Flux) before scheduling application workloads. Mirror the same Flux paths as testing so `infra-cilium` runs first.

## Current Helm values (phase 1)

- `ipam.mode=kubernetes` — use `Node.spec.podCIDR` from Kubernetes (matches k3s defaults).
- `routingMode=tunnel` — overlay between nodes; fits k3d and typical single-L2 homelab segments.
- `kubeProxyReplacement=false` — keep k3s kube-proxy until you deliberately migrate.
- `bgpControlPlane.enabled=false` — enable in Helm when adding manifests under `bgp/`.

## Implementation plan (phased)

1. **Design and inventory** — Record node interfaces/subnets and current service exposure paths; decide native routing vs tunnel for production; define BGP peering matrix.

1. **Bootstrap Cilium in testing** — Done for phase 1: Helm release + k3d bootstrap hook; BGP off.

1. **Enable BGP control plane** — Set `bgpControlPlane.enabled=true`, add BGP CRs under `bgp/`, advertise test prefixes, verify peers.

1. **Traffic and policy hardening** — Baseline network policies; confirm Envoy Gateway and tunnel paths.

1. **Production promotion** — Environment-specific ASNs/peers; incremental node rollout.

## Validation checklist

- `cilium status` and operator health are green.
- BGP peers are `Established` and expected prefixes are advertised/received (after phase 2).
- Service reachability works from LAN and tunnel entrypoints.
- DNS, cert-manager ACME/webhook paths, and Envoy Gateway routes remain functional.
- No packet-loss spikes or route-flap storms during steady state.

## Risks and rollback

- **Primary risk:** transient cluster networking disruption during CNI migration.
- **Mitigation:** phased testing first, explicit maintenance window, pre-staged rollback manifests.
- **Rollback approach:** revert Flux to prior networking stack commit and force reconcile; keep known-good previous manifests tagged for fast recovery.

## Upstream

- [Cilium documentation](https://docs.cilium.io/)
- [Cilium BGP Control Plane](https://docs.cilium.io/en/stable/network/bgp-control-plane/)
- [Cilium Kubernetes installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

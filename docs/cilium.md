# Cilium (eBGP networking)

**Status:** Planned - **not** present in `k3s/` yet

**Scope:** Introduce **Cilium** as the cluster CNI and enable **BGP control plane (eBGP)** for routable service IP advertisement to the homelab network.

## Goals

- Replace/standardize cluster networking on Cilium with kube-proxy replacement enabled where supported.
- Use Cilium BGP control plane to advertise service VIPs/LB ranges toward upstream router peers.
- Keep ingress exposure predictable for Envoy Gateway and future services while reducing ad-hoc L2 behavior.
- Establish a network-policy baseline (`default-deny` + explicit allow rules) after migration stability.

## Prerequisites and assumptions

- k3s version and host kernel support required eBPF features for target Cilium release.
- Router/switch peers can run eBGP sessions with cluster node addresses (or dedicated loopbacks).
- BGP ASN and peering plan are reserved (local ASN, peer ASNs, prefixes to advertise).
- Maintenance window exists for networking cutover and test-cluster validation before production.

## Proposed GitOps layout

When implemented, place manifests under the network controller tree:

- `k3s/infrastructure/controllers/network/cilium/cilium.yaml` - HelmRepository + HelmRelease.
- `k3s/infrastructure/controllers/network/cilium/kustomization.yaml` - wrapper.
- `k3s/infrastructure/controllers/network/cilium/bgp/` - `CiliumBGPPeeringPolicy`, pools, advertisements.
- `k3s/infrastructure/testing/kustomization.yaml` - include `../controllers/network/cilium`.

## Implementation plan (phased)

1. **Design and inventory**

   - Record node interfaces/subnets and current service exposure paths.
   - Decide Cilium mode (`kubeProxyReplacement`, tunnel/native routing, IPAM mode).
   - Define BGP peering matrix (neighbors, ASN, timers, failure behavior).

1. **Bootstrap Cilium in testing**

   - Add Cilium Helm source/release with conservative defaults.
   - Keep BGP disabled initially; verify pod networking, DNS, and API reachability.
   - Validate existing workloads (`hello-world`, Envoy Gateway control/data plane, cert-manager webhooks).

1. **Enable BGP control plane**

   - Add BGP CRDs/policies and service advertisement config.
   - Advertise a controlled test prefix first, then production-intended LB/service ranges.
   - Verify peering health and route propagation on both cluster and router sides.

1. **Traffic and policy hardening**

   - Add baseline network policies in audit-first sequence.
   - Confirm ingress behavior with Envoy Gateway and Cloudflare tunnel dependencies.
   - Document operational runbooks (peer loss, route flap, rollout/rollback commands).

1. **Production promotion**

   - Mirror tested values/manifests into prod cluster path with environment-specific peers/ASNs.
   - Roll out node groups incrementally and confirm route convergence after each step.

## Validation checklist

- `cilium status` and operator health are green.
- BGP peers are `Established` and expected prefixes are advertised/received.
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

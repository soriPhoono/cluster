# MetalLB (removed)

**Status:** **Removed** — **MetalLB is no longer used.** LoadBalancer VIPs and their advertisement are handled by **Cilium LB IPAM** and the **Cilium BGP control plane** (see [cilium.md](cilium.md)).

## Historical paths (deleted)

The following were deleted when migrating to Cilium:

- `k3s/infrastructure/controllers/network/metallb/`
- `k3s/infrastructure/testing/suplemental/metallb-pools.yaml`

## Upstream

- [MetalLB documentation](https://metallb.io/) — reference only if you compare behavior while debugging.

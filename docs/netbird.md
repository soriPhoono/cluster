# NetBird and Mullvad exit design

**Status:** Planned — **not** present in `k3s/` yet

**Scope:** Intended mesh VPN and egress architecture for this homelab. **Identity** for NetBird (users, groups, login) is planned to come from **Authentik** as the network’s OIDC authority—see [authentik.md](authentik.md).

## Goals

1. **Self-hosted NetBird control plane** on the cluster (management API, dashboard, coordination, and related components per [NetBird self-hosting](https://docs.netbird.io/selfhosted/selfhosted-guide) guidance), with **Authentik** configured as the **OpenID Connect** identity provider.
1. **Five exit-node workloads**, each running in its own pod (or Deployment replica set), where **all egress traffic** from that exit node is routed through **Mullvad**—similar in spirit to Tailscale’s Mullvad exit-node integration: clients use your exit; the exit’s Internet path is the VPN provider’s network.

## GitOps paths

No HelmRelease or raw manifests yet. When implemented, expect something like:

- `k3s/infrastructure/controllers/` or `k3s/apps/<name>/` for NetBird management components.
- Separate workloads (Deployments or StatefulSets) for each exit region, with a **sidecar** or **init** + shared network namespace pattern that enforces default route via Mullvad (WireGuard/OpenVPN or vendor-supported container—choose based on Mullvad’s current automation options and your threat model).

Document concrete chart versions, namespaces, and Mullvad credential injection (Kubernetes Secrets, SOPS) here once manifests exist.

## Upstream

- [NetBird documentation](https://docs.netbird.io/)
- [NetBird self-hosted quickstart](https://docs.netbird.io/selfhosted/selfhosted-quickstart)
- [NetBird: Self-hosted Identity Providers](https://docs.netbird.io/selfhosted/identity-providers)
- [Mullvad help](https://mullvad.net/en/help) (connection types, WireGuard keys)

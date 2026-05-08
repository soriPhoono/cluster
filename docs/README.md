# Guenivir cluster documentation

Per-stack notes for this GitOps repo: what is **deployed** today versus **planned**, where manifests live under `k3s/`, and pointers to upstream operator docs.

| Document | Status | Summary |
| --- | --- | --- |
| [flux-and-clusters.md](flux-and-clusters.md) | Deployed | Flux entrypoint, testing vs prod, `infrastructure.yaml` flow |
| [traefik.md](traefik.md) | Deployed | Ingress controller, dashboard, GitOps paths |
| [metallb.md](metallb.md) | Deployed | Service LoadBalancer IP allocation for testing cluster |
| [cert-manager.md](cert-manager.md) | Deployed | TLS operator, Helm release |
| [gitops-and-secrets.md](gitops-and-secrets.md) | Deployed | SOPS, Flux decryption, developer secrets |
| [cloudflare-operator.md](cloudflare-operator.md) | Deployed | Tunnels to Traefik; placeholders for zone/token |
| [netbird.md](netbird.md) | Planned | Control plane, Mullvad exits; mesh IdP via Authentik |
| [authentik.md](authentik.md) | Planned | Network IdP: NetBird OIDC + Traefik / app SSO |
| [cilium.md](cilium.md) | Planned | CNI + eBGP networking migration and rollout plan |
| [vmstack.md](vmstack.md) | Planned | Monitoring/observability stack rollout and alerting plan |
| [cloudnativepg.md](cloudnativepg.md) | Planned | PostgreSQL via CloudNativePG |

Repository overview and roadmap table: [../README.md](../README.md).

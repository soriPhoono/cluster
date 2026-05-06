# Authentik

**Status:** Planned — **not** present in `k3s/` yet

**Scope:** **De facto identity authority** for the homelab network—**OIDC IdP for NetBird** (who can join the mesh and group claims) and **SSO / reverse-proxy auth** for the Traefik dashboard and other HTTP services. Mesh design: [netbird.md](netbird.md).

## Goals

- Run **Authentik** on-cluster (or a supported external deployment) as the single place users and groups are defined for **both** VPN access and web apps.
- Configure **NetBird** self-hosted management to use Authentik as its **OpenID Connect** identity provider (users sign in to NetBird through Authentik; optional group-to-policy mapping per NetBird docs).
- Integrate with **Traefik** using common patterns such as **ForwardAuth** middleware, or Authentik’s application proxy integration, so only authenticated users reach the Traefik dashboard API and other admin surfaces.

## GitOps paths

None yet. When added, typical artifacts include:

- Authentik Helm release or upstream manifests.
- Traefik `Middleware` CRDs (or Ingress annotations) pointing at Authentik’s outpost / verify URL.
- `Ingress` or `IngressRoute` for Authentik itself, backed by cert-manager `Certificate` objects.
- NetBird management `openid` (or equivalent) settings and OAuth client registration in Authentik for the NetBird dashboard and agents.

## Upstream

- [Authentik documentation](https://docs.goauthentik.io/)
- [Traefik ForwardAuth](https://doc.traefik.io/traefik/master/middlewares/http/forwardauth/)
- [NetBird: Self-hosted Identity Providers](https://docs.netbird.io/selfhosted/identity-providers)

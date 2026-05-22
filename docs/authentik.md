# Authentik

**Status:** Implemented in `k3s/` for the testing cluster

**Scope:** **De facto identity authority** for the homelab network—**OIDC IdP for NetBird** (who can join the mesh and group claims) and the future auth layer for private HTTP services. Mesh design: [netbird.md](netbird.md).

## Current design

- Run **Authentik** on-cluster as a dedicated application in the `authentik` namespace.
- Back Authentik with **CloudNativePG-managed PostgreSQL** instead of chart-managed database dependencies.
- Expose Authentik through **Envoy Gateway** using **Gateway API** on `auth.cryptic-coders.net`.
- Publish `auth.cryptic-coders.net` on the testing **ClusterTunnel** via a `TunnelBinding` that targets the Authentik Envoy data plane (same pattern as [`hello-world/publication.yaml`](../k3s/apps/manifests/hello-world/publication.yaml)).
- Keep **NetBird OIDC integration** for a later step once the NetBird control plane is present.

## Notes

- Current Authentik releases no longer require **Redis**; PostgreSQL is the only external stateful dependency needed for this rollout.
- The Authentik route is HTTP on the Envoy/Gateway path; the Cloudflare tunnel forwards public traffic to the Authentik Envoy proxy service in `envoy-gateway-system`.

## GitOps paths

- `k3s/infrastructure/controllers/databases/cloudnative-pg/` - CloudNativePG operator install.
- `k3s/apps/manifests/authentik/` - Authentik namespace, encrypted secrets, PostgreSQL cluster, Gateway, Cloudflare tunnel binding, and Helm release.
- `k3s/clusters/testing/authentik-testing.yaml` - Flux `Kustomization` for the Authentik app bundle.

## Future follow-up

- Configure NetBird to use Authentik as its **OpenID Connect** identity provider.
- Authentik Helm release or upstream manifests.
- Traefik `Middleware` CRDs (or Ingress annotations) pointing at Authentik’s outpost / verify URL.
- `Ingress` or `IngressRoute` for Authentik itself, backed by cert-manager `Certificate` objects.
- NetBird management `openid` (or equivalent) settings and OAuth client registration in Authentik for the NetBird dashboard and agents.
  \=======
- Add application providers, outposts, and access policies once private apps are onboarded.

## Upstream

- [Authentik documentation](https://docs.goauthentik.io/)
- [Authentik Kubernetes installation](https://docs.goauthentik.io/docs/install-config/install/kubernetes)
- [Authentik configuration reference](https://docs.goauthentik.io/install-config/configuration)
- [NetBird: Self-hosted Identity Providers](https://docs.netbird.io/selfhosted/identity-providers)
- [CloudNativePG documentation](https://cloudnative-pg.io/documentation/current/)

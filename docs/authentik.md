# Authentik

**Status:** Implemented in `k3s/` for the testing cluster

**Scope:** **De facto identity authority** for the homelab network—**OIDC IdP for NetBird** (who can join the mesh and group claims) and the future auth layer for private HTTP services. Mesh design: [netbird.md](netbird.md).

## Current design

- Run **Authentik** on-cluster as a dedicated application in the `authentik` namespace.
- Back Authentik with **CloudNativePG-managed PostgreSQL** instead of chart-managed database dependencies.
- Expose Authentik through **Envoy Gateway** using **Gateway API** on `auth.cryptic-coders.net`.
- Keep **Cloudflare tunnel publication deferred** for now, so the route host already matches the final public hostname without creating the tunnel binding in this step.
- Keep **NetBird OIDC integration** for a later step once the NetBird control plane is present.

## Notes

- Current Authentik releases no longer require **Redis**; PostgreSQL is the only external stateful dependency needed for this rollout.
- The initial Authentik route is HTTP on the internal Envoy/Gateway path. Later tunnel publication can front the same host without renaming Gateway or HTTPRoute resources.

## GitOps paths

- `k3s/infrastructure/controllers/databases/cloudnative-pg/` - CloudNativePG operator install.
- `k3s/apps/manifests/authentik/` - Authentik namespace, encrypted secrets, PostgreSQL cluster, Gateway, and Helm release.
- `k3s/clusters/testing/authentik-testing.yaml` - Flux `Kustomization` for the Authentik app bundle.

## Future follow-up

- Configure NetBird to use Authentik as its **OpenID Connect** identity provider.
- Add a Cloudflare `TunnelBinding` for `auth.cryptic-coders.net`.
- Add application providers, outposts, and access policies once private apps are onboarded.

## Upstream

- [Authentik documentation](https://docs.goauthentik.io/)
- [Authentik Kubernetes installation](https://docs.goauthentik.io/docs/install-config/install/kubernetes)
- [Authentik configuration reference](https://docs.goauthentik.io/install-config/configuration)
- [NetBird: Self-hosted Identity Providers](https://docs.netbird.io/selfhosted/identity-providers)
- [CloudNativePG documentation](https://cloudnative-pg.io/documentation/current/)

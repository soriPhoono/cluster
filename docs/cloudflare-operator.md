# Cloudflare operator and tunnels

**Status:** Deployed via Flux HelmRelease and app-level tunnel manifests.

**Scope:** [adyanth/cloudflare-operator](https://github.com/adyanth/cloudflare-operator) installs `cloudflared` and manages `Tunnel` + `TunnelBinding` resources. This cluster fronts **Traefik** (not ingress-nginx) per the [tunnel binding with reverse proxy](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/tunnel-binding-with-reverse-proxy) pattern.

## GitOps paths

| Resource | Path |
| --- | --- |
| Operator HelmRelease | [`../k3s/infrastructure/controllers/cloudflare-operator-helmrelease.yaml`](../k3s/infrastructure/controllers/cloudflare-operator-helmrelease.yaml) |
| Secret (SOPS) | [`../k3s/infrastructure/configs/secrets/cloudflare-api-token.sops.yaml`](../k3s/infrastructure/configs/secrets/cloudflare-api-token.sops.yaml) |
| Demo app tunnel resources | [`../k3s/apps/testing/nginx-hello`](../k3s/apps/testing/nginx-hello) |
| Flux Kustomizations | [`../k3s/clusters/testing/infrastructure.yaml`](../k3s/clusters/testing/infrastructure.yaml), [`../k3s/clusters/testing/apps.yaml`](../k3s/clusters/testing/apps.yaml) |

## What you must configure

1. **API token** — Edit the encrypted secret (only `stringData` is encrypted):

   ```bash
   sops k3s/infrastructure/configs/secrets/cloudflare-api-token.sops.yaml
   ```

   Set `CLOUDFLARE_API_TOKEN` to a Cloudflare token with permissions required by the operator (see [operator authentication example](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/operator-authentication)).

1. **Tunnel** — In [`tunnel.yaml`](../k3s/apps/testing/nginx-hello/tunnel.yaml), set:

   - `spec.cloudflare.email` (email on the Cloudflare account, used for some API paths),
   - `spec.cloudflare.domain` (zone apex managed in Cloudflare),
   - `spec.cloudflare.accountId` (Cloudflare account ID from dashboard),
   - `spec.cloudflare.secret` to the secret name `cloudflare-api-token`.

1. **TunnelBinding** — In [`tunnel-binding.yaml`](../k3s/apps/testing/nginx-hello/tunnel-binding.yaml), set `subjects[0].spec.fqdn` to the public host (example: `demo.cryptic-coders.net`) and keep it aligned with Traefik host rules.

1. **Later: Authentik / NetBird** — Add additional `TunnelBinding` objects (more specific hostnames **before** the wildcard binding) so those hostnames reach Traefik; Traefik routes to backends by `Ingress` / `IngressRoute` as usual. See the upstream doc section on route ordering and the `zz-` prefix for catch-all rules.

## Traefik as reverse proxy

The demo binding sends HTTP to `http://traefik.traefik.svc.cluster.local:80`, matching the upstream “HTTP to ingress” example. When you terminate TLS on Traefik with cert-manager, consider switching the binding target to `https://traefik.traefik.svc.cluster.local:443` and tuning `noTlsVerify` / origin CA per the upstream example.

## Upstream

- [Getting started](https://github.com/adyanth/cloudflare-operator/blob/main/docs/getting-started.md)
- [Tunnel binding + reverse proxy](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/tunnel-binding-with-reverse-proxy)
- [Cloudflare Tunnel docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

# Cloudflare operator and tunnels

**Status:** Deployed (operator + GitOps scaffolding); **replace placeholders** before expecting a working tunnel.

**Scope:** [adyanth/cloudflare-operator](https://github.com/adyanth/cloudflare-operator) installs `cloudflared` and manages **ClusterTunnel** + **TunnelBinding** resources. This cluster fronts **Traefik** (not ingress-nginx) per the [tunnel binding with reverse proxy](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/tunnel-binding-with-reverse-proxy) pattern.

## GitOps paths

| Resource | Path |
| --- | --- |
| Operator (remote Kustomize, pinned `ref=`) | [`../k3s/infrastructure/controllers/cloudflare-operator`](../k3s/infrastructure/controllers/cloudflare-operator) |
| Tunnel + secret + binding | [`../k3s/infrastructure/cloudflare`](../k3s/infrastructure/cloudflare) |
| Flux `Kustomization` (after controllers) | [`../k3s/clusters/testing/infrastructure.yaml`](../k3s/clusters/testing/infrastructure.yaml) (`infra-cloudflare`) |

## What you must configure

1. **API token** — Edit the encrypted secret (only `stringData` is encrypted):

   ```bash
   sops k3s/infrastructure/cloudflare/cloudflare-secrets.sops.yaml
   ```

   Set `CLOUDFLARE_API_TOKEN` to a Cloudflare token with permissions required by the operator (see [operator authentication example](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/operator-authentication)).

1. **ClusterTunnel** — In [`cluster-tunnel.yaml`](../k3s/infrastructure/cloudflare/cluster-tunnel.yaml), replace:

   - `REPLACE_ME@example.com` (email on the Cloudflare account, used for some API paths),
   - `REPLACE_ME.example.com` (zone apex you manage in Cloudflare),
   - `REPLACE_ME_ACCOUNT_ID` (Cloudflare account ID from the dashboard),
   - `newTunnel.name` if you want a different tunnel name in Cloudflare.

1. **TunnelBinding** — In [`tunnel-binding-traefik.yaml`](../k3s/infrastructure/cloudflare/tunnel-binding-traefik.yaml), set `subjects[0].spec.fqdn` to `*.<your-zone>` so it matches the same zone as the ClusterTunnel `domain`.

1. **Later: Authentik / NetBird** — Add additional `TunnelBinding` objects (more specific hostnames **before** the wildcard binding) so those hostnames reach Traefik; Traefik routes to backends by `Ingress` / `IngressRoute` as usual. See the upstream doc section on route ordering and the `zz-` prefix for catch-all rules.

## Traefik as reverse proxy

The wildcard binding sends HTTP to `http://traefik.traefik.svc.cluster.local:80` with `noTlsVerify: true`, matching the upstream “HTTP to ingress” example. When you terminate TLS on Traefik with cert-manager, consider switching the binding target to `https://traefik.traefik.svc.cluster.local:443` and tuning `noTlsVerify` / origin CA per the commented snippets in the upstream example.

## Upstream

- [Getting started](https://github.com/adyanth/cloudflare-operator/blob/main/docs/getting-started.md)
- [Tunnel binding + reverse proxy](https://github.com/adyanth/cloudflare-operator/tree/main/docs/examples/tunnel-binding-with-reverse-proxy)
- [Cloudflare Tunnel docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

# Cloudflare Tunnel demo manifests

These resources create a **`ClusterTunnel`** and **`TunnelBinding`** so **cloudflared** forwards public hostname traffic to your ingress Service, matching the stack in [`../../clusters/testing`](../../clusters/testing).

## Secret `cloudflare-api-credentials`

**`ClusterTunnel`** loads API credentials from the **operator** namespace: **`cloudflare-operator-system`**, not `traefik`. The same secret name is referenced by `spec.cloudflare.secret`.

Create it before the tunnel can succeed:

1. **One-off (testing):**

   ```bash
   kubectl create secret generic cloudflare-api-credentials \
     --namespace=cloudflare-operator-system \
     --from-literal=CLOUDFLARE_API_TOKEN='<token-with-zone-and-tunnel-permissions>'
   ```

1. **GitOps + SOPS:** add `cloudflare-api-credentials.sops.yaml` next to this README (encrypted with `.sops.yaml` rules), containing a normal Kubernetes `Secret` with `stringData` keys per [upstream Tunnel spec](https://github.com/adyanth/cloudflare-operator). Flux decrypts it because the [`infra-cloudflare`](../../clusters/testing/cloudflare.yaml) Flux `Kustomization` uses SOPS.

## Replace placeholders

Edit [`tunnel.yaml`](tunnel.yaml), [`tunnel-binding.yaml`](tunnel-binding.yaml), and [`../../demo/ingressroute.yaml`](../../demo/ingressroute.yaml): use the **same FQDN** (e.g. `demo.yourdomain.com`) and set `spec.cloudflare.domain` to your Cloudflare **zone** name.

## DNS (Cloudflare dashboard)

**`TunnelBinding.tunnelRef.name` must match the tunnel resource** (`Tunnel` or **`ClusterTunnel`**) **`metadata.name`** (here: `demo`), not `spec.newTunnel.name`. A wrong name breaks the binding, `cloudflared` config, and automatic DNS.

**Your zone shows a wildcard `*` CNAME to the apex.** That can make `demo.cryptic-coders.net` follow the wildcard instead of the tunnel. Add an **explicit** record for `demo` that wins for that host:

- **Preferred:** let the operator create it (requires a token with **Zone → DNS → Edit** and the binding working). Reconcile the `Tunnel` / `TunnelBinding` and check **DNS → Records** for a proxied CNAME for `demo` toward `<tunnel-id>.cfargotunnel.com`.
- **Manual:** Zero Trust → your tunnel → copy the tunnel hostname, then **DNS → Add record**: **Type** CNAME, **Name** `demo`, **Target** `<uuid>.cfargotunnel.com`, **Proxy** on (orange cloud).

Until `demo` exists as a **tunnel-backed** proxied record, the browser will show Cloudflare tunnel / connection errors even if the cluster is healthy.

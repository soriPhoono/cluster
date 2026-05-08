# Envoy Gateway Ingress Migration Runbook

## Validate

1. Reconcile Flux and wait for `infra` and `apps-testing` Kustomizations to become ready.
1. Confirm `envoy-gateway` HelmRelease is ready in `flux-system`.
1. Confirm Gateway API objects are accepted in `hello-world`:
   - `GatewayClass/envoy`
   - `Gateway/hello-world-gateway`
   - `HTTPRoute/hello-world`
1. Validate end-to-end traffic:
   - `hello-world.cryptic-coders.net` resolves and returns the app through the tunnel.
   - Request headers/response status match previous baseline behavior.

## Rollback

1. Reintroduce Traefik controller manifests (`k3s/infrastructure/controllers/core/traefik.yaml`) and add it back to `k3s/infrastructure/controllers/core/kustomization.yaml`.
1. Change `k3s/apps/manifests/hello-world/ingress.yaml` tunnel `target` back to:
   - `http://traefik.traefik.svc.cluster.local:80`
1. Replace Gateway API resources with Traefik `IngressRoute` for `hello-world`.
1. Reconcile Flux and verify the app is reachable again through Traefik.

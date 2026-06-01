# Guenivir — Multi-Cluster Kubernetes GitOps

GitOps repository for a personal **multi-cluster Kubernetes** stack. A single codebase that deploys identical application and infrastructure manifests across multiple Kubernetes targets:

| Cluster | Runtime | Purpose |
|---|---|---|
| **`testing`** | k0s in Docker | Local development and validation on laptop |
| **`guenivir`** | k0s / TalOS Linux | Private homelab bare-metal cluster |
| **`gke-*`** | GKE (Google Cloud) | Business application workloads |

A **k0s** cluster in Docker applies the **same Flux path and manifests** so changes can be exercised locally before deploying to TalOS or GKE.

**Stack and runbooks:** [docs/](docs/README.md) (per-component pages). **Editor and agent tooling:** [AGENTS.md](AGENTS.md).

## Why k0s

[k0s](https://k0sproject.io/) is a CNCF-certified, single-binary Kubernetes distribution from Mirantis. It provides a standard, upstream-aligned Kubernetes API with zero host dependencies — ideal for running identically across Docker (testing), bare metal (TalOS), and managed cloud (GKE).

## Repository and Flux source

The Flux `GitRepository` in [`k8s/clusters/testing/flux-system/gotk-sync.yaml`](k8s/clusters/testing/flux-system/gotk-sync.yaml) points at `https://github.com/soriphoono/guenivir.git`. The reconciled path is `./k8s/clusters/` on the branch Flux tracks, where each subdirectory is a cluster target.

## What Flux deploys today

Reconciliation entrypoint: [`k8s/clusters/testing`](k8s/clusters/testing) — each cluster directory has `apps/` and `infra/` subdirectories containing Flux `Kustomization` manifests with explicit dependency ordering.

### Dependency chain

```
cert-manager ─┬── traefik (depends: cert-manager)
              ├── cloudflare-operator (depends: cert-manager)
cloudnative-pg

    apps/hello-world (depends: cert-manager, cloudflare-operator, traefik)
    apps/authentik   (depends: cert-manager, cloudflare-operator, cloudnative-pg)
    apps/netbird     (depends: authentik, traefik, cloudflare-operator)
```

### Current stack

| Layer | What |
|---|---|
| **Infrastructure** | cert-manager (TLS), Cloudflare Operator (DNS/tunnels), Traefik (ingress), CloudNative-PG (PostgreSQL) |
| **Applications** | Authentik (identity provider), NetBird (mesh VPN), hello-world (test workload) |

Details: [docs/](docs/README.md).

## Repository layout

```
k8s/                              # Multi-cluster Kubernetes config
├── apps/                         # Shared application manifests
│   └── manifests/
│       ├── hello-world/
│       ├── authentik/
│       └── netbird/
├── infra/                        # Shared infrastructure components
│   └── components/
│       ├── databases/cloudnative-pg/
│       ├── network/cert-manager/
│       ├── network/traefik/
│       └── dns/cloudflare-operator/
├── clusters/
│   ├── testing/                  # k0s in Docker (laptop / local dev)
│   │   ├── flux-system/          # Flux sync (generated)
│   │   ├── apps/                 # Per-cluster app Flux Kustomizations
│   │   │   ├── hello-world.yaml
│   │   │   ├── authentik.yaml
│   │   │   └── netbird.yaml
│   │   ├── infra/                # Per-cluster infra Flux Kustomizations
│   │   │   ├── cert-manager.yaml
│   │   │   ├── cloudnative-pg.yaml
│   │   │   ├── traefik.yaml
│   │   │   └── cloudflare-operator.yaml
│   │   └── kustomization.yaml
│   └── guenivir/                 # TalOS bare metal (future)
│       ├── apps/
│       └── infra/
docs/                             # Per-stack documentation
```

## Getting started

```bash
direnv allow    # optional: load dev shell via .envrc
nix develop     # enter dev shell
nix run         # create k0s cluster in Docker, bootstrap Flux
```

### What `nix run` does

1. Starts a k0s container in Docker (controller + worker, single-node)
1. Extracts kubeconfig for local `kubectl` access
1. Creates `flux-system` namespace and injects the SOPS age key
1. Bootstraps Flux against `k8s/clusters/testing/`
1. Flux reconciles all manifests — infra components first, then apps

### Tear down

```bash
docker rm -f k0s-guenivir-testing
```

Formatting, linting, pre-commit, and agent-oriented commands: **[AGENTS.md](AGENTS.md)**.

## Encrypting secrets

- **Cluster (`k8s/`)**: use SOPS-encrypted manifests; Flux decrypts using the `sops-age` secret. See [docs/gitops-and-secrets.md](docs/gitops-and-secrets.md).
- **Developer secrets**: use **age** and **agenix-shell** as configured in the flake; full notes live in [docs/gitops-and-secrets.md](docs/gitops-and-secrets.md).

Quick cluster secret example:

```bash
kubectl create secret generic my-secret \
  --from-literal=key=value \
  --dry-run=client -o yaml > k8s/apps/manifests/my-app/my-secret.sops.yaml
sops -e -i k8s/apps/manifests/my-app/my-secret.sops.yaml
```

(Adjust path to match the Flux `Kustomization` that should include the file.)

______________________________________________________________________

## name: testing-cluster-deploy description: 'Deploy and manage the local k3d testing cluster that bootstraps FluxCD and reconciles the full GitOps configuration from this repository.'

# Testing Cluster Deploy Pipeline

**INVOKE WHEN:** The user mentions "testing cluster", "test cluster", "nix run", "k3d", "deploy cluster", "reconcile", "spin up the testing environment", "bootstrap flux", "test the deployment", or asks about exercising the full GitOps pipeline locally.

**DO NOT USE FOR:** General cluster debugging of an already-running cluster, Kubernetes manifest edits, or Flux troubleshooting that doesn't involve the deployment lifecycle.

## Pipeline Overview

The `nix run` command in this flake executes a full local testing pipeline:

```
nix run
  └─ k3d cluster delete k3d-guenivir-testing     # teardown old
  └─ k3d cluster create k3d-guenivir-testing     # spin up fresh k3s-in-Docker
  └─ kubectl create namespace flux-system        # prep bootstrap namespace
  └─ kubectl create secret sops-age              # inject SOPS age key for encrypted secrets
  └─ flux bootstrap github ...                   # bootstrap Flux pointing at current branch
       └─ Flux reconciles k3s/clusters/testing/  # syncs all manifests from the repo
```

This creates a **full-stack local test environment** that mirrors production — every CRD, controller, application, and tunnel binding from the repo gets deployed and reconciled by Flux.

## Prerequisites

| Requirement | Details |
|---|---|
| **Docker** | k3d runs k3s in Docker containers. Must be installed and the daemon running. |
| **Nix** | The Nix daemon must be running (`sudo systemctl start nix-daemon` or equivalent). |
| **Age keys** | `GITHUB_TOKEN` and `TESTING_AGE_KEY` are decrypted via `agenix-shell` on entering the devShell. Requires your SSH identity key (`~/.ssh/id_ed25519`) to be present. |
| **GitHub auth** | `flux bootstrap github` uses `--token-auth` — ensure your `GITHUB_TOKEN` is valid and has repo scope. |
| **Current branch** | Flux bootstraps from the **currently checked-out branch**. Push your changes first, or the cluster will reconcile the remote branch state, not your local uncommitted changes. |

## Workflow

### Standard deploy cycle

```bash
# 1. Make your changes to manifests in k3s/
# 2. Commit and push (Flux reconciles from the remote branch)
git add -A && git commit -m "feat: my change" && git push

# 3. Enter the devShell
nix develop

# 4. Run the pipeline
nix run
```

### Quick iteration without push

For rapid testing of local changes **before** pushing:

1. Make edits to manifests in `k3s/`
1. Run `nix run` to spin up the cluster with Flux bootstrapped from the branch
1. After bootstrapping, manually apply your uncommitted changes:

```bash
kubectl apply -k k3s/apps/manifests/authentik/
# or for specific resources:
kubectl apply -f k3s/apps/manifests/authentik/ingress.yaml
```

Note: `flux bootstrap` syncs from the **remote** branch. If you haven't pushed, Flux will reconcile whatever is currently on the remote. For local-only changes, apply them with `kubectl` after bootstrap completes.

### Deploy to a specific branch

```bash
# Check out your feature branch
git checkout feat/my-feature
git push -u origin feat/my-feature

# Deploy — Flux will bootstrap from the current branch
nix run
```

## What happens step by step

| Step | Command | Purpose |
|---|---|---|
| 1 | `k3d cluster delete k3d-guenivir-testing` | Remove any existing test cluster for a clean slate |
| 2 | `k3d cluster create --k3s-arg '--disable=traefik@server:*' --k3s-arg '--disable=servicelb@server:*' --image rancher/k3s:v1.31.5-k3s1 --wait --timeout 120s k3d-guenivir-testing` | Create single-node k3s cluster in Docker with Traefik and ServiceLB disabled (MetalLB/Envoy Gateway replaces them) |
| 3 | `kubectl create namespace flux-system` | Ensure the Flux bootstrap namespace exists before SOPS secret injection |
| 4 | `kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=$TESTING_AGE_KEY_PATH` | Inject the cluster's SOPS age key so Flux can decrypt `.sops.yaml` secrets during reconciliation |
| 5 | `flux bootstrap github --owner=soriphoono --repository=guenivir --branch=$(git rev-parse --abbrev-ref HEAD) --path=k3s/clusters/testing --personal --token-auth` | Bootstrap FluxCD from the current branch, using `k3s/clusters/testing` as the sync root. Flux installs itself, creates the `GitRepository` and `Kustomization` resources, and begins reconciling |

## Cluster topology after bootstrap

Once `nix run` completes, the cluster has:

```
k3d-guenivir-testing (k3s v1.31.5)
  └── FluxCD (deployed by bootstrap)
      ├── GitRepository (guenivir, current branch)
      ├── Kustomization: infra (infrastructure batch operation)
      │   ├── metallb (loadbalancing)
      │   ├── envoy-gateway (ingress)
      │   ├── cert-manager (certificates)
      │   ├── vmstack operator (monitoring)
      │   ├── cloudnative-pg (postgresql management)
      │   └── cloudflare-operator (cloudflare management)
      ├── Kustomization: infra-suplemental (infrastructure configuration -- CLUSTER SPECIFIC)
      │   ├── metallb-pools (IP Address alocations for metallb)
      │   ├── envoy-gateway (Envoy gateway class)
      │   └── cluster-tunnel (cloudflare tunnel advertisement, all public resources are bound to this tunnel in cloudflare for the cluster)
      └── Kustomization: apps
          ├── authentik
          │   ├── PostgreSQL Cluster (CloudNativePG)
          │   ├── Authentik HelmRelease
          │   ├── Gateway Configuration
          │   └── TunnelBinding (Cloudflare)
          └── hello-world (Testing, you can disregard this)
```

## Verification commands

Run these after `nix run` completes to verify the cluster is healthy:

```bash
# --- Cluster & Node State ---
k3d cluster list                            # confirm cluster exists
kubectl cluster-info                        # control plane health
kubectl get nodes -o wide                   # node readiness

# --- Flux Health ---
flux check                                  # Flux component health
flux get kustomizations -A                  # all Kustomization statuses
flux get helmreleases -A                    # all HelmRelease statuses
flux tree kustomization authentik-testing   # visual dependency tree for authentik

# --- Namespace & Pod Health ---
kubectl get pods -A                         # all pods across all namespaces
k9s                                         # interactive TUI (in devShell)

# --- SOPS / Secrets ---
kubectl get secrets -n authentik            # encrypted secrets should be decrypted and present

# --- Gateway & Tunnel ---
kubectl get gateways -A                     # envoy gateways
kubectl get httproutes -A                   # HTTP routes
kubectl get tunnelbindings -A               # cloudflare tunnel bindings
kubectl get tunnels -A                      # cluster tunnels
```

## Troubleshooting

### Deployment fails on step 2 (cluster create)

```text
failed to create cluster: ... cgroups: memory cgroup v2 ...
```

**Cause:** k3d/k3s requires cgroup v2 memory controller delegation. This is **not available** in Cloud Agent VMs (Docker-in-Docker inside Firecracker) or other nested container environments.

**Fix:** Run on bare metal, a VM, or WSL2 — not inside a Cloud Agent / CI container that itself runs inside a VM.

### Deployment fails on step 4 or 5 (SOPS / flux bootstrap)

```text
Error: age: no matching identity file
```

**Cause:** `agenix-shell` could not decrypt `TESTING_AGE_KEY` because your SSH key is missing or not loaded.

**Fix:**

```bash
# Verify SSH key is present
ls -la ~/.ssh/id_ed25519

# Enter devShell (will try to decrypt)
nix develop
# The agenix-shell may emit a harmless stderr warning but still export TESTING_AGE_KEY_PATH
# if the secret is cached from a previous successful decrypt
```

### Flux bootstraps but Kustomizations fail

```text
Kustomization/authentik-testing  False  Progressing  error: ... health check failed ...
```

**Common causes:**

1. **Cluster hasn't finished provisioning** — controllers (CNPG, cert-manager, envoy) take time to come up. Flux retries automatically.
1. **Wrong branch** — Flux bootstraps from the current branch. If your changes are on a different branch, Flux syncs whatever is on the remote HEAD.
1. **SOPS key mismatch** — the `sops-age` secret in `flux-system` must match the age key used to encrypt `.sops.yaml` files. Run `kubectl get secret sops-age -n flux-system -o yaml` to verify.

**Diagnose:**

```bash
flux get kustomizations -A                           # see which Kustomizations are failing
kubectl describe kustomization <name> -n flux-system # detailed error
flux logs                                            # Flux controller logs
```

### Envoy Gateway pods not starting

```text
CrashLoopBackOff: failed to find envoy binary
```

This can happen if the envoy gateway controller hasn't finished pulling images. Wait a few minutes and re-check:

```bash
kubectl get pods -n envoy-gateway-system -w
```

If pods remain in `CrashLoopBackOff` after 5 minutes, check the envoy-gateway HelmRelease health:

```bash
flux get helmrelease envoy-gateway -n flux-system
```

### TunnelBinding stuck in progress

Cloudflare tunnels need a valid API token. Verify the encrypted secret is present:

```bash
kubectl describe tunnelbinding -n authentik
kubectl get secrets -n cloudflare-operator-system
```

If the API token is missing or expired, you'll need to update the SOPS-encrypted secret at `k3s/infrastructure/controllers/dns/cloudflare-operator/cloudflare-api-token.sops.yaml`.

## Cloud Agent VM limitation

Per `AGENTS.md`: **k3d / k3s clusters cannot run in Cloud Agent VMs.** The nested container environment (Docker-in-Docker inside Firecracker) lacks cgroup v2 memory controller delegation. k3s exits with `failed to find memory cgroup (v2)`. This means `nix run` (deploy) will not work in these environments.

However, all other dev tasks work normally in Cloud Agent VMs:

- `nix fmt` (formatting, linting)
- `nix develop` (dev shell with tools)
- Editing manifests in `k3s/`
- Pre-commit hooks
- Running `kubectl` / `flux` commands against a remote cluster

## Related project resources

| Resource | Path |
|---|---|
| Flake definition (deploy app) | `flake.nix` (lines 74-121) |
| DevShell definition | `shell.nix` |
| AGENTS.md (project instructions) | `AGENTS.md` |
| Flux & cluster docs | `docs/flux-and-clusters.md` |
| Cluster bootstrap entrypoint | `k3s/clusters/testing/` |
| Cloudflare operator docs | `docs/cloudflare-operator.md` |

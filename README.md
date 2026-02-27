# Server Home Lab Cluster

This repository contains the configuration, definitions, and orchestration files for a self-hosted Kubernetes cluster. The infrastructure is built on **Talos Linux** (immutable OS), managed declaratively through **Nix**, and deployed continuously via **Flux** GitOps.

## Project Structure

- **`k8s/clusters/`**: Per-cluster Flux entrypoints. Currently contains two clusters:
  - **`adams/`** — The primary production cluster.
  - **`testing/`** — An isolated environment for validating changes before promoting to production.
- **`k8s/infrastructure/`**: Core platform components reconciled by Flux, including:
  - `cert-manager` — Automatic TLS certificate management.
  - `cloudflare-tunnel` — Secure ingress tunneling via Cloudflare.
  - `external-dns` — Automatic DNS record management.
  - `metallb` — Bare-metal load balancer.
  - `monitoring` — Prometheus-based observability stack.
  - `rook-ceph` — Distributed block and object storage.
  - `traefik` — Ingress controller and reverse proxy.
- **`k8s/apps/`**: Application workloads deployed on top of the platform.
- **`talos/`**: Talos Linux node machine configs (Talosctl-managed).
- **`controlplane.yaml` & `worker.yaml`**: Base Talos machine configuration patches.
- **`secrets/`**: Encrypted secrets managed with `agenix` + `sops`/`age`.
- **`lib/`**: Custom Nix library functions.
- **`flake.nix` & `shell.nix`**: Reproducible development environment, packages, and hooks.
- **`actions.nix`**: GitHub Actions workflow definitions (via `github-actions-nix`).
- **`secrets.nix`**: Ownership declarations for secrets, used by `agenix` for rotation and editing.
- **`pre-commit.nix`**: Pre-commit hook definitions.
- **`treefmt.nix`**: Repository-wide formatter configuration.

## Getting Started

To get started developing or administering the cluster:

1. **Enter the Nix Shell**:
   If you have `direnv` set up, simply `cd` into the directory and the shell will load automatically (`direnv allow` on first run). Alternatively:

   ```bash
   nix develop
   ```

1. **Pre-commit Hooks**:
   The shell provisions `pre-commit` hooks automatically (formatting with `treefmt`, `alejandra`, etc.).

1. **Cluster Tools**:
   The shell also provides `kubectl`, `flux`, `talosctl`, `kubeconform`, `sops`, and `agenix` for interacting with the cluster.

## Kubernetes Manifest Requirements

When adding a new workload or modifying an existing manifest in `k8s/`, you **MUST** adhere to the following strict requirements:

1. **Image pinning**: Pin images to a specific version or digest — never `latest`.
1. **Declarative**: All resources must be defined as YAML manifests within `k8s/`.
1. **Validation**: All manifests must pass `kubeconform` validation.
1. **Healthchecks**: Configure `livenessProbe` and `readinessProbe` for all services.
1. **Secrets**: NEVER commit plain-text secrets. Use `sops` with `age` encryption for `Secret` resources.
1. **Resources**: Define `requests` and `limits` for all containers.

## Contributing

Please see the [`CONTRIBUTING.md`](CONTRIBUTING.md) file for guidelines on making changes, updating infrastructure, and deploying stacks.

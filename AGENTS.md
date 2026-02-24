# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Environment & Development

This repository uses **Nix** to manage the development environment and tooling.

- **Shell**: The environment is defined in `flake.nix` and `shell.nix`.
  - Ensure you are in the dev shell: run `nix develop` or allow `direnv`.
- **Tools**:
  - `kubectl`: Kubernetes CLI.
  - `talosctl`: Talos Linux CLI for node management.
  - `sops` & `age`: Secret management.
  - `kustomize`: Kubernetes configuration management (if applicable).
- **Formatting & Linting**:
  - **Auto-formatting**: Run `treefmt` (or `nix fmt`) to format all files.
    - Nix: `alejandra`
    - Shell: `shfmt`
    - YAML: `yamlfmt`
  - **Linting**: Pre-commit hooks enforce quality checks.
    - Run all checks: `pre-commit run --all-files`
    - **Validation**: `kubeconform` validates Kubernetes manifests.
    - **Secrets**: `gitleaks` checks for plaintext secrets.

## Architecture & Structure

This repository manages a **Kubernetes cluster** running on **Talos Linux**.

- **OS**: [Talos Linux](https://www.talos.dev) - An immutable, minimal, API-managed Kubernetes OS.
- **Orchestration**: Kubernetes.
- **`k8s/`**: Directory containing Kubernetes manifests and cluster configurations.
- **`lib/`**: Custom Nix library functions.
- **`flake.nix`**: Defines the reproducible toolchain.

## Critical Rules: Kubernetes & Talos

When working with this cluster, you **MUST** strictly adhere to the following:

### Talos Linux

1. **Immutability**: Never attempt to SSH into nodes. Use `talosctl` for all node operations.
1. **Configuration**: Node configuration is declarative. Changes should be made to the machine configuration files and applied via `talosctl apply-config`.
1. **Upgrades**: Use `talosctl upgrade` for OS updates, ensuring proper drain/uncordon procedures.

### Kubernetes Manifests

1. **Declarative**: All resources must be defined in YAML manifests within `k8s/`.
1. **Validation**: All manifests must pass `kubeconform` validation.
1. **Images**:
   - **Pinning**: NEVER use `latest`. Pin to a specific version or digest (e.g., `image: nginx:1.25.3`).
1. **Resources**: Define `requests` and `limits` for all containers.
1. **Healthchecks**: Configure `livenessProbe` and `readinessProbe` for all services.
1. **Secrets**: NEVER commit plain text secrets. Use `sops` with `age` encryption for `Secret` resources.

## Common Workflows

### Validating Changes

Before submitting changes:

1. Format code: `treefmt`
1. Run checks: `pre-commit run --all-files` (includes `kubeconform`).

### Managing Secrets

To edit an encrypted secret:

```bash
sops k8s/path/to/secret.yaml
```

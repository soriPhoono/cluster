# Server Home Lab Cluster

This repository contains the configuration, definitions, and orchestration files for our self-hosted Kubernetes cluster. This environment is built using Nix and Talos Linux to achieve a reproducible and orchestrated infrastructure.

## Project Structure

- **`k8s/apps`**: Contains Kubernetes manifests and definitions for the different workloads running in the cluster.
- **`k8s/clusters`**: Contains Kubernetes manifests and definitions for the different clusters this infrastructure manages, with optional segregation of testing code.
- **`secrets/`**: Contains encrypted secrets for the cluster, managed with agenix.
- **`lib/`**: Contains custom Nix library functions.
- **`flake.nix` & `shell.nix`**: Defines the reproducible development environment, packages, and hooks needed to work on this repository.
- **`actions.nix`**: Defines the GitHub Actions workflow for this repository.
- **`secrets.nix`**: Defines ownership of files in the `secrets/` directory, used with agenix as a
  built-in editor for secrets management, and as a source of truth for secrets rotation.
- **`pre-commit`**: Defines pre-commit hooks for code quality.
- **`treefmt.nix`**: Defines the treefmt configuration for the repository.

## Getting Started

To get started developing or administering the cluster:

1. **Enter the Nix Shell**:
   If you have `direnv` and Nix set up, simply `cd` into the directory and the environment will load. Alternatively, run:
   ```bash
   nix develop
   ```
1. **Pre-commit Hooks**:
   The development environment automatically provisions `pre-commit` hooks (formatting with `treefmt`, `alejandra`, etc.) to ensure code quality.

## Kubernetes Manifest Requirements

When adding a new workload or modifying an existing manifest in `k8s/`, you **MUST** adhere to the following strict requirements:

1. **Image pinning**: Images must be pinned to a specific version or digest (avoid using `latest`).
1. **Declarative**: All resources must be defined in YAML manifests within `k8s/`.
1. **Validation**: All manifests must pass `kubeconform` validation.
1. **Healthchecks**: Configure `livenessProbe` and `readinessProbe` for all services.
1. **Secrets**: NEVER commit plain text secrets. Use `sops` with `age` encryption for `Secret` resources.
1. **Resources**: Define `requests` and `limits` for all containers.

## Contributing

Please see the [`CONTRIBUTING.md`](CONTRIBUTING.md) file for guidelines on making changes, updating infrastructure, and deploying stacks.

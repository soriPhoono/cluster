# Contributing to the Server Home Lab Cluster

Thank you for contributing to the Home Lab cluster! This environment is strongly declarative and version-controlled. By following these guidelines, you help keep the infrastructure reliable and reproducible.

## Table of Contents

1. [Development Environment](#development-environment)
1. [Repository Layout](#repository-layout)
1. [Adding or Modifying Workloads](#adding-or-modifying-workloads)
   - [Strict Kubernetes Requirements](#strict-kubernetes-requirements)
1. [Applying Changes via Flux](#applying-changes-via-flux)
1. [AI Agent Guidelines](#ai-agent-guidelines)
1. [Pull Requests & Code Style](#pull-requests--code-style)

## Development Environment

This project relies heavily on **Nix**. We enforce the use of the provided environment to ensure all configurations and `pre-commit` hooks execute identically across machines.

- **Setup**: Ensure `nix` with flakes enabled is installed. If you use `direnv`, allow the environment with `direnv allow`.
- **Manual Entry**: If not using `direnv`, launch the development shell:
  ```bash
  nix develop
  ```
- **Pre-commit Hooks**: The Nix shell automatically configures git hooks to run formatters (`treefmt`, `alejandra`).
- **Cluster Tools**: The shell provides `kubectl`, `flux`, `talosctl`, `kubeconform`, `sops`, and `agenix`.

## Repository Layout

| Path | Purpose |
|------|---------|
| `k8s/clusters/adams/` | Production cluster Flux entrypoint |
| `k8s/clusters/testing/` | Testing cluster for validating changes |
| `k8s/infrastructure/` | Platform-level components (cert-manager, metallb, traefik, rook-ceph, monitoring, etc.) |
| `k8s/apps/` | Application workloads |
| `talos/` | Talos Linux machine configs managed via `talosctl` |
| `secrets/` | `sops`-encrypted secret files |

## Adding or Modifying Workloads

All deployed applications and their configurations track back to declarative Kubernetes manifests in `k8s/`.

1. **New infrastructure components** (ingress controllers, storage, monitoring): add under `k8s/infrastructure/<component>/` and reference from the appropriate cluster's `infrastructure.yaml`.
1. **New application workloads**: add under `k8s/apps/<app-name>/` and reference from the cluster's Flux kustomization.
1. **All manifests** must be declared as `Kustomization` resources (or `HelmRelease`) and reconciled through Flux — do not apply resources manually with `kubectl`.

### Strict Kubernetes Requirements

We strictly validate Kubernetes manifests using `kubeconform`. If you do not follow these rules, your service will either fail to deploy or be rejected in review:

- **Image pinning**: Never use the `latest` tag. Always pin to a specific, reproducible version or digest.
- **Declarative Configuration**: Avoid manual `kubectl apply` commands. All resources (Deployments, Services, ConfigMaps, etc.) must be declared in YAML.
- **Healthchecks**: Configure `livenessProbe` and `readinessProbe` to ensure containers are healthy before receiving traffic.
- **Secrets**: Never commit plain-text secrets. Use `sops` with `age` encryption for `Secret` resources.
- **Resource Limits**: Define both `requests` and `limits` for all containers to ensure stable scheduling.

## Applying Changes via Flux

This cluster uses **Flux** for GitOps. Changes merged to the tracked branch are automatically reconciled. To manually trigger reconciliation during development:

```bash
# Reconcile a specific kustomization and its source
flux reconcile kustomization <name> --with-source

# Watch all Flux resources
flux get all -A

# Force reconcile the infrastructure kustomization
flux reconcile kustomization infrastructure --with-source
```

Wherever possible, validate changes against the **`testing`** cluster before targeting **`adams`** (production).

## AI Agent Guidelines

If you are an AI autonomous agent (like Antigravity or Gemini), please consult `AGENTS.md` for architectural context and check `.agents/workflows/` for step-by-step procedures. The development shell automatically mounts necessary MCP servers to your runtime context if you are running inside this workspace (Antigravity only).

## Pull Requests & Code Style

- **Formatting**: Pre-commit hooks format Nix and YAML files. Ensure these pass locally before opening a PR.

- **Commit Messages**: This project follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. Use the following types:

  - `feat`: A new feature or workload addition.
  - `fix`: A bug fix or configuration correction.
  - `docs`: Documentation-only changes.
  - `style`: Formatting changes that do not affect behavior.
  - `refactor`: A change that neither fixes a bug nor adds a feature.
  - `chore`: Changes to the build process or auxiliary tools.
  - `infra`: Changes to cluster infrastructure components.

  **Example**: `feat(infra): add traefik ingress controller`

- **Testing**: State how you verified your changes — e.g., `kubeconform` output, Flux reconciliation on the `testing` cluster, or `talosctl` node status.

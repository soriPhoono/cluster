# AI Agent Guidelines for `server` Repository

Welcome! This document provides essential context, architectural rules, and workflows to help AI agents navigate and contribute to this repository effectively.

## Core Technologies

- **Nix / NixOS**: The environment and toolchain are managed via Nix. `flake.nix` is the primary entry point.
- **Kubernetes**: We use Kubernetes for orchestrating workloads.
- **Talos Linux**: An immutable OS for our Kubernetes nodes.

## Key Files & Configuration

- **`k8s/`**: Directory containing all declarative Kubernetes manifests.
- **`shell.nix`**: Defines the development environment. It automatically installs `pre-commit` hooks and handles integrating Gemini/Antigravity MCP servers if you are running in the Antigravity editor context.
- **`README.md`**: Contains the critical Kubernetes Manifest Requirements.

## Strict Kubernetes Requirements

When creating or modifying Kubernetes manifests for the cluster, you **MUST** adhere to the following rules:

1. **Image pinning**: Images must be pinned to a specific version tag or digest. Do not use `latest`.
1. **Declarative**: All edits must be made via YAML manifests located in `k8s/`.
1. **Validation**: Enforce `kubeconform` checks on all manifests.
1. **Healthchecks**: Must explicitly configure `livenessProbe` and `readinessProbe` to ensure pods are ready before receiving traffic.
1. **Secrets**: Utilize `sops` and `age` to encrypt secrets. Do not commit plaintext secrets.
1. **Limits**: Define CPU and Memory `requests` and `limits` for predictability.

## Extensible Workflows

If you need to perform routine tasks (like deploying a new stack), please check the `.agents/workflows/` directory for specific step-by-step workflow files to ensure you follow the project's exact operational procedures.

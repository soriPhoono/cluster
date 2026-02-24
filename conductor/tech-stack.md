# Technology Stack

## Environment & Tooling

- **Nix (Flakes & Shell)**: Used for managing the development environment, toolchain versions, and reproducible environments.
- **Pre-commit**: Orchestrates quality checks, including formatting and linting.

## Infrastructure & Orchestration

- **Talos Linux**: An immutable, API-managed Linux distribution for Kubernetes nodes.
- **Kubernetes (k8s)**: The container orchestration platform for all workloads.

## Security & Secrets

- **SOPS**: Used for encrypting and decrypting secrets within the repository.
- **age**: The modern encryption tool used as the backend for SOPS.
- **ssh-to-age**: Utility to convert SSH keys to age format for decryption access.

## CLI Tools

- **kubectl**: Kubernetes command-line tool.
- **talosctl**: Talos Linux command-line tool for node management.
- **treefmt**: Unified formatter for multiple languages.
- **alejandra**: Opinionated Nix code formatter.
- **nil**: Language server for Nix.

## Development Workflow

- **Direnv**: Automatically loads the Nix environment upon entering the project directory.

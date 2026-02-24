# AI Agent Guidelines for `server` Repository

Welcome! This document provides essential context, architectural rules, and workflows to help AI agents navigate and contribute to this repository effectively.

## Core Technologies

- **Nix / NixOS**: The environment and toolchain are managed via Nix. `flake.nix` is the primary entry point.
- **Docker Swarm**: We use Docker Swarm for orchestrating services.

## Key Files & Configuration

- **`stacks.yaml`**: Specifies the repositories, branches, and relative paths to the Docker Compose files for the stacks running in our cluster.
- **`shell.nix`**: Defines the development environment. It automatically installs `pre-commit` hooks and handles integrating Gemini/Antigravity MCP servers if you are running in the Antigravity editor context.
- **`README.md`**: Contains the critical Swarm Service Requirements.

## Docker Swarm Strict Requirements

When creating or modifying Docker Compose files (`docker-compose.yaml`) for Swarm, you **MUST** adhere to the following rules:

1. **Image pinning**: Images must be pinned to a specific version tag. Do not use `latest`.
1. **Deploy configuration**: All Swarm-specific settings must reside under the `deploy` block:
   - `restart_policy`: Configured for failure resilience (e.g., `condition: on-failure`).
   - `placement`: Appropriate node constraints (e.g., `node.role == manager`).
   - `update_config`: Must be defined for rolling updates.
1. **Healthcheck**: Must be explicitly configured to ensure the task is fully ready before it receives traffic.
1. **Secrets & Configs**: Prefer Swarm `secrets` and `configs` over plain environment variables for sensitive data or files.
1. **Networks**: Must use `driver: overlay` for cross-node swarm communication (typically defined in the infra stack).
1. **Labels**: Traefik and other service discovery labels must be placed under `deploy.labels`, **not** container-level `labels`.

## Extensible Workflows

If you need to perform routine tasks (like deploying a new stack), please check the `.agents/workflows/` directory for specific step-by-step workflow files to ensure you follow the project's exact operational procedures.

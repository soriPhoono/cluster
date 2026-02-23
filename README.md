# Server Home Lab Cluster

This repository contains the configuration, definitions, and orchestration files for our self-hosted Docker Swarm cluster. This environment is built using Nix and Docker Swarm to achieve a reproducible and orchestrated infrastructure.

## Project Structure

- **`.agents/`**: Contains AI-agent workflows and configurations. Learn how agents interact with this repository in [`agents.md`](agents.md).
- **`docker/`**: Contains Docker Compose files and stack definitions for the different services running in the Swarm.
- **`lib/`**: Contains custom Nix library functions.
- **`flake.nix` & `shell.nix`**: Defines the reproducible development environment, packages, and hooks needed to work on this repository.
- **`stacks.yaml`**: The single source of truth for all deployed applications. It specifies the repository, branch, and relative path to the compose files for every stack in the cluster.

## Getting Started

To get started developing or administering the cluster:

1. **Enter the Nix Shell**:
   If you have `direnv` and Nix set up, simply `cd` into the directory and the environment will load. Alternatively, run:
   ```bash
   nix develop
   ```
1. **Pre-commit Hooks**:
   The development environment automatically provisions `pre-commit` hooks (formatting with `treefmt`, `alejandra`, etc.) to ensure code quality.

## Swarm Service Requirements

When adding a new service or modifying an existing `docker-compose.yaml` file, you **MUST** adhere to the following strict requirements:

1. **Image pinning**: Images must be pinned to a specific version (avoid using `latest`).
1. **Deploy configuration**: Swarm settings must be defined under the `deploy` block:
   - `restart_policy`: Configured for failure resilience (e.g., `condition: on-failure`).
   - `placement`: Appropriate node constraints (e.g., `node.role == manager`).
   - `update_config`: Defined for rolling updates.
1. **Healthcheck**: Configured to ensure the task is ready before receiving traffic.
1. **State & Configs**: Volumes configured if required. Prefer Swarm `secrets` and `configs` over plain environment variables for sensitive data or files.
1. **Environment variables**: Explicitly configured if required.
1. **Networks**: Must use `driver: overlay` for cross-node swarm communication. (Usually defined in the main infra stack).
1. **Labels**: Traefik and other agent discovery labels must be placed under `deploy.labels`, **not** container-level `labels`.

## Contributing

Please see the [`CONTRIBUTING.md`](CONTRIBUTING.md) file for guidelines on making changes, updating infrastructure, and deploying stacks.

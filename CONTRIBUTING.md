# Contributing to the Data Fortress

Thank you for contributing to the **Data Fortress**! This project is a highly declarative, multi-tier environment optimized for efficiency and performance. By following these guidelines, you help maintain the stability and reproducibility of the cluster.

______________________________________________________________________

## 🏗️ Development Environment

This project relies on **Nix** to ensure a consistent, reproducible toolchain across all contributor machines.

1. **Enter the Environment**: Use `nix develop` or `direnv allow` to load the shell.
1. **Required Tools**: The shell provides `docker` (Swarm client), `nh` (Nix helper), `sops`, and `agenix`.
1. **Pre-commit Hooks**: We use `treefmt` and `git-hooks-nix` to enforce formatting and basic checks before code is committed.

______________________________________________________________________

## 🔐 Secrets Workflow

We maintain a strict separation between development and production runtime secrets.

### 1. Developer Secrets (`agenix-shell`)

Used for tool authentication and environment variables within the Nix shell.

- **To add/update**:
  - Edit the appropriate `.age` secret file in `secrets/`.
  - Update `secrets.nix` with any new ownership or rotation rules.
  - Run `agenix -e <secret-file>.age` to edit the secret.

### 2. Service Secrets (Docker Swarm / SOPS)

Used by containerized services at runtime.

- **To add/update**:
  - Use `sops` to encrypt and manage secrets in the `stacks/` directory.
  - Reference these in your `docker-compose.yml` under the `secrets:` key.
  - **Best Practice**: Secret names should be versioned (e.g., `db_password_v1`) to allow for smooth rotation without service downtime.

______________________________________________________________________

## 🚀 Adding or Modifying Stacks

All services are defined in the \[**`stacks/`**\](stacks) directory.

1. **Define the Stack**: Create or modify a `docker-compose.yml` within a subdirectory of `stacks/`.
1. **Compose Best Practices**:
   - **Image Pinning**: Avoid `latest` tags. Pin to a specific version or hash.
   - **Resource Management**: Always define `reservations` and `limits` for CPU/Memory.
   - **Networks**: Assign services to relevant overlay networks (e.g., `traefik-public` for ingress).
1. **Register the Stack**: Add the new stack definition to \[**`stacks.yml`**\](stacks.yml) to enable tracking by `swarm-cd`.

______________________________________________________________________

## 🎮 Gaming Tier (Pterodactyl)

All services are defined in the \[**`stacks/`**\](stacks) directory.
We use the **Pterodactyl Panel** on the Proxmox tier to manage game servers across the Gaming Tier (Mini PCs).

- **Adding Game Eggs**: To add a new game type or modify an existing one, update the configuration in the corresponding Pterodactyl service stack or management script.
- **Runner Management**: To add or update a Pterodactyl "Wing" (runner), configure the node labels on the Swarm manager to ensure the runner is scheduled correctly on the Gaming Tier mini PCs.

1. Register the Stack: Add the new stack definition to \[**`stacks.yml`**\](stacks.yml) to enable tracking by `swarm-cd`.

## 🔄 Deployment via `swarm-cd`

The cluster uses a custom `swarm-cd` controller for GitOps reconciliation.

- Improvements to the CD logic should be made in `docker-compose.yml` at the root.
- To trigger a manual reconciliation, you can use the `swarm-cd` service directly or trigger a build in the CI pipeline (`actions.nix`).

______________________________________________________________________

## 📝 Commit Messages & PRs

We follow the [**Conventional Commits**](https://www.conventionalcommits.org/) specification:

- `feat`: A new stack or hardware tier integration.
- `fix`: A configuration correction.
- `infra`: Changes to the core Swarm manager or Proxmox nodes.
- `docs`: Documentation updates.
- `game`: Specific updates to Pterodactyl or game server configurations.

**Example**: `feat(game): add minecraft runner to gaming tier`

# Contributing to the Data Fortress

Thank you for contributing to the **Data Fortress**! This project is a highly declarative environment currently migrating from Kubernetes to Docker Swarm.

______________________________________________________________________

## 🏗️ Development Environment

We use standard Docker tools and `direnv` to maintain a consistent environment.

1. **Enter the Environment**: Use `direnv allow` to load environment variables from `.envrc`.
2. **Required Tools**: Ensure you have `docker`, `docker-compose`, `sops`, and `trunk` installed.
3. **Pre-commit Hooks**: We use `trunk` to enforce formatting and linting (see `.trunk/` for configuration).

______________________________________________________________________

## 🔐 Secrets Workflow

We maintain a strict separation between development and production runtime secrets.

### 1. Developer Secrets

Managed via environment variables in `.envrc` and secured using `sops` where necessary.

### 2. Service Secrets (Docker Swarm / SOPS)

Used by containerized services at runtime.

- **To add/update**:
  - Use `sops` to encrypt and manage secrets in the stack directories (e.g., `docker/stacks/<app>/secrets/`).
  - Reference these in your `docker-compose.yml` under the `secrets:` key.
  - **Best Practice**: Use Docker native secrets for Swarm-deployed services.

______________________________________________________________________

## 🚀 Adding or Modifying Stacks

All services are defined in the [**`docker/stacks/`**](docker/stacks/) directory.

1. **Define the Stack**: Create or modify a `docker-compose.yml` within a subdirectory of `docker/stacks/`.
2. **Compose Best Practices**:
   - **Image Pinning**: Avoid `latest` tags. Pin to a specific version.
   - **Resource Management**: Define `reservations` and `limits` for CPU/Memory in the `deploy` section.
   - **Networks**: Use relevant overlay networks (e.g., `public` for Traefik ingress).
3. **Register the Stack**: Add the new stack definition to [**`docker/clusters/adams/stacks.yml`**](docker/clusters/adams/stacks.yml) to enable tracking by `swarm-cd`.

______________________________________________________________________

## 🔄 Deployment via `swarm-cd`

The cluster uses `swarm-cd` for GitOps reconciliation.

- To trigger a deployment, push changes to the `main` branch.
- `swarm-cd` monitors the `stacks.yml` file and reconciles the cluster state.

______________________________________________________________________

## 📝 Commit Messages & PRs

We follow the [**Conventional Commits**](https://www.conventionalcommits.org/) specification:

- `feat`: A new stack or hardware tier integration.
- `fix`: A configuration correction.
- `infra`: Changes to core Swarm or cluster configuration.
- `docs`: Documentation updates.
- `refactor`: Changes that neither fix a bug nor add a feature.

**Example**: `feat(stacks): add jellyfin stack to media nodes`


# Contributing to the Data Fortress

Thank you for contributing to the **Data Fortress**! This project is a highly declarative environment managed via GitOps on Docker Swarm. Following these guidelines ensures the cluster remains stable, secure, and reproducible.

---

## 🏗️ Development Workflow

We use standard Docker tools to maintain a consistent environment across human and agent collaborators.

1.  **Tooling**: Ensure you have `docker`, `sops`, and [trunk](https://trunk.io) installed.
2.  **Code Quality**: We use [trunk](https://trunk.io) to enforce formatting and linting. Always run `trunk check` before committing changes.

---

## 🚀 Adding or Modifying Stacks

All services are defined as Docker Compose stacks in the [**`docker/stacks/`**](docker/stacks/) directory.

1.  **Define the Stack**: Create or modify a `docker-compose.yml` within a subdirectory of `docker/stacks/`.
2.  **Standard Practices**:
    -   **Image Pinning**: Never use the `latest` tag. Always pin to a specific version or digest for reproducibility.
    -   **Networks**: Use the `reverse-proxy_public` overlay network for external exposure via Traefik.
    -   **Security**: Mount the Docker socket (`/var/run/docker.sock`) directly only when absolutely necessary, and always use the `:ro` (read-only) flag unless write access is explicitly required for management.
3.  **Register the Stack**: Add the stack definition to [**`docker/clusters/adams/stacks.yml`**](docker/clusters/adams/stacks.yml). This enables **`swarm-cd`** to track and deploy the stack automatically.

---

## 🔐 Secrets Workflow

We strictly separate developer-level secrets from production runtime secrets.

### 1. Developer Secrets
- Managed as local environment variables (e.g., in a `.env` file or shell session).
- These are for tools interacting with the cluster or external APIs.

### 2. Service Secrets
- Encrypted via `sops` and typically located in `docker/stacks/<stack-name>/secrets/`.
- Reference these in the `secrets:` section of your `docker-compose.yml`.
- Preferred method is using Docker native secrets for Swarm workloads.

---

## 🔄 Deployment via `swarm-cd`

The cluster follows a GitOps model:
- To trigger a deployment, push your changes to the `main` branch.
- **`swarm-cd`** monitors `stacks.yml` and reconciles the cluster state accordingly.
- Monitor deployment status via `docker service logs` on a manager node.

---

## 📝 Commit Guidelines

We follow the [**Conventional Commits**](https://www.conventionalcommits.org/) specification:

-   `feat`: Adding a new stack or major architectural component.
-   `fix`: Correcting a configuration error or bug.
-   `infra`: Changes to core cluster management or GitOps definitions.
-   `docs`: Documentation updates.
-   `refactor`: Code changes that neither fix a bug nor add a feature.

**Example**: `feat(stacks): add portainer for cluster management`

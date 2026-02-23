______________________________________________________________________

## description: How to create and configure a new Docker Swarm stack

# Workflow: Create a New Stack

This workflow defines the exact steps an agent should take when a user asks to add a new service or stack to the home lab cluster. Always follow these steps strictly to ensure compliance with the repository's configuration standards.

## 1. Update the Main Registry

The central registry for all deployed applications is `stacks.yaml`. You must register the new service here so the automation knows it exists.

1. Open `stacks.yaml`.
1. Add a new top-level map key for the stack name.
1. Define the required fields: `repo`, `branch`, and `compose_file`.
   - Usually, `repo` will be this repository name or something similar, and `branch` is `main`.
   - `compose_file` should point relative to the repository root, e.g., `docker/<stack_name>/docker-compose.yaml`.

Example update to `stacks.yaml`:

```yaml
new_stack_name:
  repo: current-repo-name
  branch: main
  compose_file: docker/new_stack_name/docker-compose.yaml
```

## 2. Create the Stack Directory

Create a dedicated directory under the `docker/` folder for the newly defined stack.

```bash
mkdir -p docker/<stack_name>
```

## 3. Create the Docker Compose File

Create the `docker-compose.yaml` file inside the newly created directory.

The most critical part of this step is ensuring the compose file abides by the **Strict Swarm Requirements**.

### Strict Swarm Requirements Checklist:

- [ ] **Image Pinning**: Use a specific tag, never `latest` (e.g., `image: postgres:15.3-alpine`).
- [ ] **Deploy Block**:
  - [ ] Must contain a `restart_policy`, typically `condition: on-failure`.
  - [ ] Must define `update_config` for rolling updates to prevent downtime.
  - [ ] Must have `placement` constraints (e.g., `node.role == manager` or `node.role == worker`).
- [ ] **Healthchecks**: Must be explicitly defined to allow Docker to know when the service can receive traffic.
- [ ] **Secrets & Configs**: If the application requires sensitive information, mock out Swarm secrets rather than using hardcoded `.env` files or variables.
- [ ] **Networks**: The service must connect to the cluster's main overlay network.
  ```yaml
  networks:
    - default
  ```
  *(Be aware that `networks` must also be declared at the bottom of the compose file specifying `driver: overlay` if this is a standalone overlay, or `external: true` if attaching to an existing one.)*
- [ ] **Labels**: Any routing/proxy labels (like Traefik) must go under `deploy.labels`.

## 4. Final Review

1. Ensure the paths specified in `stacks.yaml` precisely match the created file locations.
1. Ask the user if they want to apply this stack immediately (if applicable via CLI commands) or if they just want a PR opened for the configuration addition.

# Contributing to the Server Home Lab Cluster

Thank you for contributing to the Home Lab cluster! This environment is intended to be strongly declarative and version-controlled. By following these guidelines, you help keep the infrastructure reliable and reproducible.

## Table of Contents

1. [Development Environment](#development-environment)
1. [Adding or Modifying Services](#adding-or-modifying-services)
   - [Strict Swarm Requirements](#strict-swarm-requirements)
1. [AI Agent Guidelines](#ai-agent-guidelines)
1. [Pull Requests & Code Style](#pull-requests--code-style)

## Development Environment

This project relies heavily on **Nix**. We enforce the use of the provided environment to ensure all configurations (`pre-commit` hooks) execute identically across machines, and follows best practices.

- **Setup**: Make sure `nix` with flakes enabled is installed. If you use `direnv`, simply allow the environment (`direnv allow`).
- **Manual Entry**: If not using `direnv`, launch the development shell by running `nix develop`.
- **Pre-commit Hooks**: The nix shell will automatically configure git hooks to run formatters (`treefmt`, `alejandra`).

## Adding or Modifying Services

All deployed applications and their configurations track back to our central registry.

1. **`stacks.yaml`**: Ensure any new stack/service is defined. This sets the repository, branch, and relative path to the Docker Compose files.
1. **Docker Compose**: Place compose files under the `docker/` directory (or according to what is specific in `stacks.yaml`).

### Strict Swarm Requirements

We strictly validate `docker-compose.yaml` files. If you do not follow these rules, your service will fail to deploy properly or be rejected in review:

- **Image pinning**: Never use the `latest` tag. Always pin to a specific, reproducible version.
- **Deploy block**: All Swarm operational settings live here.
  - Set a `restart_policy` (e.g., `condition: on-failure`).
  - Configure `update_config` to avoid downtime during rollouts.
  - Add appropriate `placement` constraints (e.g., `node.role == manager`).
- **Healthchecks**: Must be configured. A container cannot receive traffic until it is healthy.
- **Secrets & Configs**: Prefer Swarm native `secrets` and `configs` instead of raw environment variables for sensitive data.
- **Overlay Networks**: Ensure the service uses the correct cross-node `overlay` network.
- **Service Labels**: Things like Traefik routing labels *must* go under `deploy.labels` (the Swarm service level), not container `labels`.

## AI Agent Guidelines

If you are an AI autonomous agent (like Antigravity or Gemini), please consult our `agents.md` index and check `.agents/workflows/` for step-by-step procedures. Our development shell automatically mounts necessary MCP servers to your runtime context if you are running inside this workspace (antigravity only).

## Pull Requests & Code Style

- **Formatting**: The pre-commit hooks will format Nix, and YAML files. Ensure these pass locally.
- **Commit Messages**: This project follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This provides a clear, readable history. Use the following types:
  - `feat`: A new feature or stack addition.
  - `fix`: A bug fix or configuration correction.
  - `docs`: Documentation only changes.
  - `style`: Changes that do not affect the meaning of the code (formatting).
  - `refactor`: A code change that neither fixes a bug nor adds a feature.
  - `chore`: Changes to the build process or auxiliary tools.
    **Example**: `feat(infra): update manager node RAM to 4GB`
- **Testing**: Whenever possible, state how you manually verified your compose file configurations or plans.

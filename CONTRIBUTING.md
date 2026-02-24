# Contributing to the Server Home Lab Cluster

Thank you for contributing to the Home Lab cluster! This environment is intended to be strongly declarative and version-controlled. By following these guidelines, you help keep the infrastructure reliable and reproducible.

## Table of Contents

1. [Development Environment](#development-environment)
1. [Adding or Modifying Workloads](#adding-or-modifying-workloads)
   - [Strict Kubernetes Requirements](#strict-kubernetes-requirements)
1. [AI Agent Guidelines](#ai-agent-guidelines)
1. [Pull Requests & Code Style](#pull-requests--code-style)

## Development Environment

This project relies heavily on **Nix**. We enforce the use of the provided environment to ensure all configurations (`pre-commit` hooks) execute identically across machines, and follows best practices.

- **Setup**: Make sure `nix` with flakes enabled is installed. If you use `direnv`, simply allow the environment (`direnv allow`).
- **Manual Entry**: If not using `direnv`, launch the development shell by running `nix develop`.
- **Pre-commit Hooks**: The nix shell will automatically configure git hooks to run formatters (`treefmt`, `alejandra`).

## Adding or Modifying Workloads

All deployed applications and their configurations track back to our Kubernetes manifests.

1. **Kubernetes Manifests**: All workloads must be defined as declarative YAML manifests under `k8s/` in their respective categorical directories (e.g., `core`, `databases`, `media-stack`).

### Strict Kubernetes Requirements

We strictly validate Kubernetes manifests using `kubeconform`. If you do not follow these rules, your service will fail to deploy properly or be rejected in review:

- **Image pinning**: Never use the `latest` tag. Always pin to a specific, reproducible version or digest.
- **Declarative Configuration**: Avoid manual `kubectl` commands. Define all resources (Deployments, Services, ConfigMaps, etc.) in YAML.
- **Healthchecks**: Configure `livenessProbe` and `readinessProbe` to ensure a container is healthy before it receives traffic.
- **Secrets**: Never commit plain text secrets. Use `sops` with `age` encryption for `Secret` resources.
- **Resource Limits**: Define both `requests` and `limits` for all containers to ensure stable scheduling.

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
- **Testing**: Whenever possible, state how you manually verified your Kubernetes manifests or configurations.

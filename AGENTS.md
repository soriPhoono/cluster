# AI Agent Guidelines for the Data Fortress

Welcome! This document provides essential context, architectural rules, and defined workflows to help AI agents (like Antigravity or Gemini) navigate and contribute to the **Data Fortress** repository effectively.

## 🤖 Agent-First Philosophy

This project is designed with **Agent-First** automation in mind. The repository acts as a "Bootstrap Black Box" — once initialized, it is intended to be managed and scaled autonomously through GitOps and CI/CD pipelines.

## 🔐 Secret Management Archetypes

To ensure security and reproducibility, we maintain two distinct archetypes for secrets. Agents MUST understand which type they are interacting with:

### 1. Developer Environment Secrets (`agenix-shell`)

Driven by the Nix flake, these secrets are intended for **human/agent tool usage** (e.g., Cloudflare API tokens, deployment keys).

- **Storage**: Defined in `secrets.nix` and managed via `agenix`.
- **Consumption**: Automatically decrypted and exported as environment variables when entering the `nix develop` shell.
- **Agent Action**: Used for interacting with external APIs or deploying via the CLI.

### 2. Service/Runtime Secrets (**Docker Swarm / SOPS**)

These secrets are intended for **containerized workloads** (e.g., database passwords, app-specific tokens).

- **Storage**: Encrypted using `sops` with the cluster's `age` key.
- **Consumption**: Injected into Docker Swarm services at runtime. They are typically mounted at `/run/secrets/<secret_name>`.
- **Agent Action**: Defined in the `secrets` section of a `docker-compose.yaml` file in the `stacks/` directory.

## 🏗️ Architectural Constraints

When modifying or adding stacks in `stacks/`, agents **MUST** adhere to these rules:

1. **Image Pinning**: Always use a specific version tag or digest. Never use `latest`.
1. **Resource Limits**: Explicitly define `reservations` and `limits` for CPU/Memory in the `deploy` section of the compose file.
1. **Network Isolation**: Use internal overlay networks for service-to-service communication. Only expose services through the **Traefik** reverse proxy.
1. **Security**: Avoid exposing the Docker socket directly. Use the defined `socket-proxy` for any service that needs to communicate with the Docker API.

## 🛠️ Essential Agent Tools

The following tools are pre-configured and should be utilized by the agent:

- **`docker`**: Primary interface for Swarm management (`docker stack deploy`, `docker node ls`).
- **`swarm-cd`**: The internal GitOps controller. To trigger a deployment, update the `stacks.yaml` file or the corresponding stack definition in `stacks/`.
- **`nh`**: Nix helper for managing the development shell and building dependencies.
- **`sops`**: Used for editing and rotating service secrets.

## 📈 Extensible Workflows

Before performing routine tasks (like onboarding a new Pi 5 node or deploying a game server), check the \[**`.agents/workflows/`**\](.agents/workflows/) directory for step-by-step procedures.
Before performing routine tasks (like onboarding a new Pi 5 node or deploying a game server), check the \[**`.agents/workflows/`**\](file:///home/soriphoono/Documents/Projects/cluster/.agents/workflows/) directory for step-by-step procedures.

# AI Agent Guidelines for the Data Fortress

Welcome! This document provides essential context, architectural rules, and defined workflows to help AI agents (like Gemini) navigate and contribute to the **Data Fortress** repository effectively during its migration to Docker Swarm.

## 🤖 Agent-First Philosophy

This project is designed with **Agent-First** automation in mind. The repository acts as a "Bootstrap Black Box" — once initialized, it is intended to be managed and scaled autonomously through GitOps and CI/CD pipelines.

## 🔐 Secret Management Archetypes

To ensure security and reproducibility, we maintain two distinct archetypes for secrets. Agents MUST understand which type they are interacting with:

### 1. Developer Environment Secrets (`direnv` / `.envrc`)

These secrets are intended for **human/agent tool usage** (e.g., Cloudflare API tokens, deployment keys).

- **Consumption**: Automatically exported as environment variables via `direnv` when entering the project directory.
- **Agent Action**: Use these variables for interacting with external APIs or managing the cluster.

### 2. Service/Runtime Secrets (**Docker Swarm / SOPS**)

These secrets are intended for **containerized workloads** (e.g., database passwords, app-specific tokens).

- **Storage**: Encrypted using `sops` or defined as Docker native secrets.
- **Consumption**: Injected into Docker Swarm services at runtime, typically mounted at `/run/secrets/<secret_name>`.
- **Agent Action**: Define secrets in the `secrets` section of a `docker-compose.yml` file in the `docker/stacks/` directory.

## 🏗️ Architectural Constraints

When modifying or adding stacks in `docker/stacks/`, agents **MUST** adhere to these rules:

1. **Image Pinning**: Always use a specific version tag or digest. Never use `latest`.
1. **Resource Limits**: Explicitly define `reservations` and `limits` for CPU/Memory in the `deploy` section of the compose file.
1. **Network Isolation**: Use internal overlay networks for service-to-service communication. Only expose services through the **Traefik** reverse proxy using labels.
1. **Security**: Avoid exposing the Docker socket directly. Use the defined `socket-proxy` (TCP endpoint) for any service that needs to communicate with the Docker API.

## 🛠️ Essential Agent Tools

The following tools are pre-configured and should be utilized by the agent:

- **`docker`**: Primary interface for Swarm management (`docker stack deploy`, `docker node ls`).
- **`swarm-cd`**: The GitOps controller. To trigger a deployment, update the `docker/clusters/adams/stacks.yml` file or the corresponding stack definition in `docker/stacks/`.
- **`sops`**: Used for editing and rotating service secrets.
- **`trunk`**: Used for linting and formatting compliance.

## 📈 Migration Context

Agents should be aware that the project is currently migrating from a Kubernetes (Talos) architecture. Refer to `TODO.md` for specific migration tasks and target state details.


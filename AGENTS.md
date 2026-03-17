# AI Agent Guidelines for the Data Fortress

Welcome! This document provides essential context, architectural rules, and defined workflows to help AI agents navigate and contribute to the **Data Fortress** repository effectively.

## 🤖 Agent-First Philosophy

This project is designed with **Agent-First** automation in mind. The repository acts as a "Bootstrap Black Box" — once initialized, it is intended to be managed and scaled autonomously through GitOps and CI/CD pipelines.

## 🏗️ Architectural Constraints

When modifying or adding stacks in `docker/stacks/`, agents **MUST** adhere to these rules:

1.  **Image Pinning**: Always use a specific version tag or digest. Never use `latest`.
2.  **Network Isolation**: Use internal overlay networks for service-to-service communication. Only expose services through the **Traefik** reverse proxy using labels.
3.  **Security**:
    -   Mount the Docker socket (`/var/run/docker.sock`) directly only for services that require cluster orchestration.
    -   **Permissions**: Most infrastructure services (like Traefik) **MUST** mount the socket as read-only (`ro`).
    -   **Management**: Only core management/deployment services (like `swarm-cd`) should be granted read-write access to the socket.

## 🔐 Secret Management Archetypes

Agents must understand the two distinct archetypes for secrets:

### 1. Developer Environment Secrets
- Used for human/agent tool usage (e.g., repository API tokens, management keys).
- **Consumption**: Managed as local environment variables (e.g., in a `.env` file or shell session).

### 2. Service/Runtime Secrets (**Docker Swarm / SOPS**)
- Used for containerized workloads at runtime.
- **Storage**: Encrypted using `sops` within stack directories.
- **Consumption**: Injected into Swarm services via the `secrets` section of a `docker-compose.yml`.

## 🛠️ Essential Agent Tools

Pre-configured tools that agents should leverage:
-   **`docker`**: Primary interface for Swarm management (`docker stack deploy`, `docker stack ps`).
-   **`swarm-cd`**: The GitOps controller. To trigger deployments, update the stack definition or `docker/clusters/adams/stacks.yml`.
-   **`sops`**: Used for editing and rotating service secrets.

## 🧠 AI Infrastructure & Intelligence

The Data Fortress leverages a hybrid AI model, combining local private resources with frontier external intelligence.

### 1. Local AI Cluster (Private & Uncensored)
- **Hardware**: Framework Laptop (128GB RAM).
- **Core Engine**: **Ollama** hosting various models for private, uncensored access.
- **Workflow Automation**: Integrated with **n8n** for agentic task orchestration.

### 2. Frontier Intelligence (Global Scale)
For broad or highly targeted intelligence where privacy/censorship constraints are acceptable:
- **Gemini API**: Utilized for frontier broad intelligence and deep reasoning.
- **Claude (Anthropic)**: Leveraged for frontier targeted intelligence and complex coding tasks.
- **Venice AI**: Paid private access to frontier models, integrated with Web3 development systems.
- **OpenRouter**: Used for general access and scaling when local/targeted systems are at capacity.

## 📈 Migration Status
The Data Fortress has successfully transitioned from a Kubernetes (Talos/Proxmox) architecture to a fully declarative Docker Swarm environment running on a unified EndeavourOS workstation and x86 mini-PC Edge tier.

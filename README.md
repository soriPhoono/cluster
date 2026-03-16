# Data Fortress: Multi-Tier Swarm & Game Cluster

Welcome to the **Data Fortress**, a high-performance, resource-efficient, and fully declarative home lab environment powered by Docker Swarm. This repository serves as the single source of truth for the entire cluster's configuration and deployment.

## 🏗️ Architecture Overview

The Data Fortress is distributed across specialized hardware tiers to optimize for CPU, RAM, and specialized AI/Gaming workloads.

```mermaid
graph TD
    subgraph "Proxmox Tier (LXC Nodes)"
        M[Swarm Managers]
        P[Management UI]
        CS[Core Services]
    end

    subgraph "Edge Tier (Raspberry Pi 5 Cluster)"
        W[Swarm Workers]
        LW[Lightweight Workloads]
    end

    subgraph "AI Tier (Mac Studio)"
        LLM[Self-Hosted LLMs]
        AI[AI/ML Agents]
    end

    subgraph "Gaming Tier (Mini PCs)"
        G[Game Runners]
        GS[Private Game Servers]
    end

    M -- Orchestrates --> W
    M -- Orchestrates --> LW
    M -- Orchestrates --> LLM
    P -- Manages --> G
    G -- Hosts --> GS
```

### Hardware Tiers

1.  **Proxmox Tier**: Virtualized LXC nodes on Proxmox VE. Hosts the Swarm managers and core infrastructure (Traefik, Portainer).
2.  **Edge Tier**: A cluster of **Raspberry Pi 5** nodes. Optimized for distributed, low-power horizontal scaling of web services.
3.  **AI Tier**: Dedicated hardware (e.g., Mac Studio) for hosting local large language models (LLMs) and supporting agentic workflows.
4.  **Gaming Tier**: High-performance nodes acting as game server runners.

## 🚀 GitOps & Automation

This cluster utilizes a **GitOps** workflow for seamless, declarative deployments:

-   **`swarm-cd`**: Automatically reconciles stack definitions from this repository to the Swarm cluster.
-   **Cluster Configuration**: Located in `docker/clusters/adams/`, defining the source of truth for deployed services via `stacks.yml`.
-   **Infrastructure as Code**: All services are defined as Docker Compose stacks in `docker/stacks/`.

## 🔐 Secret Management

We maintain a strict distinction between developer and service secrets:

-   **Developer Secrets**: Managed as local environment variables (e.g., in a `.env` file or shell session). these are for tools interacting with the cluster or external APIs.
-   **Service Secrets**: Encrypted via `sops` or managed as native Docker secrets. Service-specific secrets are located within their respective stack directories.

## 🛠️ Getting Started

### 1. Environment Setup

Ensure you have `docker`, `sops`, and `trunk` installed.

### 2. Management Tools

-   `docker`: Directly interact with the Swarm manager.
-   `sops`: For secret encryption/decryption (requires a configured age key).
-   [trunk](https://trunk.io): For linting and formatting compliance across the repository.

---

For detailed contribution guidelines, see [**`CONTRIBUTING.md`**](CONTRIBUTING.md).
For AI Agent specific context, see [**`AGENTS.md`**](AGENTS.md).

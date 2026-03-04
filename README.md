# Data Fortress: Multi-Tier Swarm & Game Cluster

Welcome to the **Data Fortress**, a high-performance, resource-efficient, and fully declarative home lab environment. This project has evolved from a Kubernetes foundation to a sophisticated **Docker Swarm** orchestration layer running across heterogeneous hardware tiers, ranging from Raspberry Pis to a Mac Studio.

## 🏗️ Architecture Overview

The Data Fortress is distributed across four specialized hardware tiers to optimize for CPU, RAM, and specialized AI/Gaming workloads.

```mermaid
graph TD
    subgraph "Proxmox Tier (LXC Nodes)"
        M[Swarm Managers]
        P[Pterodactyl Panel]
        CS[Core Services]
    end

    subgraph "Edge Tier (8x Raspberry Pi 5 8GB)"
        W[Swarm Workers]
        LW[Lightweight Workloads]
    end

    subgraph "AI Tier (Mac Studio)"
        LLM[Self-Hosted LLMs]
        AI[AI/ML Agents]
    end

    subgraph "Gaming Tier (3x Mini PCs)"
        G[Pterodactyl Wings]
        GS[Private Game Servers]
    end

    M -- Orchestrates --> W
    M -- Orchestrates --> LW
    M -- Orchestrates --> LLM
    P -- Manages --> G
    G -- Hosts --> GS
```

### Hardware Tiers

1. **Proxmox Tier**: Virtualized LXC nodes on Proxmox VE. Hosts the Swarm managers, core infrastructure (Traefik, Socket Proxy), and the **Pterodactyl Panel**.
1. **Edge Tier**: A cluster of **8x Raspberry Pi 5 (8GB)** nodes. Optimized for distributed, low-power horizontal scaling of web services and data processing.
1. **AI Tier**: A **Mac Studio** dedicated to hosting local large language models (LLMs) and supporting the Antigravity/Gemini agentic workflows.
1. **Gaming Tier**: **3x Mini PCs** acting as Pterodactyl runners (Wings), hosting private game servers for low-latency performance.

## 🚀 GitOps & Automation

This cluster utilizes a **GitOps** workflow for seamless deployments:

- **`swarm-cd`**: Automatically reconciles stack definitions from this repository to the Swarm cluster.
- **`stacks.yaml`**: The source of truth for all deployed services.
- **Nix Flake**: The entire development environment, CI/CD pipelines (`actions.nix`), and secret management are defined via a unified Nix flake.

## 📂 Repository Structure

| Path | Purpose |
|------|---------|
| `stacks/` | Declarative Docker Compose stack definitions. |
| `scripts/` | Maintenance, backup, and automation scripts. |
| `secrets/` | Encrypted secrets managed via SOPS and Age. |
| `lib/` | Custom Nix library functions for the flake. |
| `stacks.yaml` | Service registration for `swarm-cd`. |
| `flake.nix` | Reproducible environment and toolchain. |

## 🔐 Secret Management

We maintain a strict distinction between developer and service secrets:

- **Developer Secrets**: Decrypted into the `nix develop` shell via `agenix-shell` for local tool usage.
- **Service Secrets**: Encrypted via `sops` and injected into Swarm services as native Docker secrets at `/run/secrets/`.

## 🛠️ Getting Started

### 1. Enter the Environment

Ensure you have Nix installed with flakes enabled.

```bash
nix develop # or 'direnv allow'
```

### 2. Management Tools

The shell provides:

- `docker`: Directly interact with the Swarm manager.
- `nh`: Nix helper for flake management.
- `sops` / `agenix`: For secret encryption/decryption.

______________________________________________________________________

For detailed contribution guidelines, see \[**`CONTRIBUTING.md`**\](file:///home/soriphoono/Documents/Projects/cluster/CONTRIBUTING.md).
For AI Agent specific context, see \[**`AGENTS.md`**\](AGENTS.md).

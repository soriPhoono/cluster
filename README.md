# Data Fortress: Multi-Tier K3s Cluster

Welcome to the **Data Fortress**, a high-performance, resource-efficient, and fully declarative home lab environment powered by K3s and FluxCD. This repository serves as the single source of truth for the entire cluster's GitOps configuration and deployment.

## 🏗️ Architecture Overview

The Data Fortress is distributed across specialized hardware tiers to optimize for productivity, privacy, and gaming, leveraging a mix of local resources and frontier AI intelligence.

```mermaid
graph TD
    subgraph "Workstation Tier (EndeavourOS)"
        PC["Gaming & Dev Workstation"]
        PH["Pi-Hole (Docker)"]
        VM["VPS Manager Node (LXC)"]
        VW["VPS Worker Node (LXC)"]
    end

    subgraph "Edge Tier (Mini-PC Cluster)"
        E1["Node 1 (Debian x86) Manager/Worker"]
        E2["Node 2 (Debian x86) Manager/Worker"]
        E3["Node 3 (Debian x86) Worker Only"]
        PW["Pterodactyl Wings (Local Game Servers)"]
    end

    subgraph "AI Cluster (Framework 128GB)"
        OL["Ollama (Private/Uncensored)"]
        N8["n8n Integration"]
        ext["Frontier Intelligence (Gemini, Claude, Venice)"]
    end

    PC -- Runs --> PH
    PC -- Runs --> VM
    PC -- Runs --> VW
    VM -- Orchestrates --> E1
    VM -- Orchestrates --> E2
    VM -- Orchestrates --> E3
    E3 -- Hosts --> PW
    OL -- Connects --> N8
```

### Hardware Tiers

1.  **Workstation Tier**: A high-spec EndeavourOS desktop serving as a primary workstation and gaming PC. It hosts LXC containers for core management (`vps-manager`, `vps-worker`) and network services (`pi-hole` on Docker).
2.  **Edge Tier**: A cluster of three **Debian x86 Mini-PCs** (16GB RAM each). Nodes 1 and 2 operate as both K3s control-plane and agents, while Node 3 acts as a dedicated agent hosting **Pterodactyl Wings** for local game server deployment.
3.  **AI Cluster**: A **Framework 128GB** laptop running **Ollama** for free, private, and uncensored agentic workflows. This local cluster integrates with **n8n** and leverages external frontier intelligence from **Gemini API**, **Claude (Anthropic)**, **Venice AI** (Web3 integrated), and **OpenRouter**.

## 🚀 GitOps & Automation

This cluster utilizes a **GitOps** workflow for seamless, declarative deployments:

- **`flux`**: Automatically reconciles manifests from this repository (under `clusters/homelab`) to the K3s cluster.
- **Cluster Configuration**: The `clusters/homelab` directory acts as the entrypoint for Flux, tracking `infrastructure` and `apps` Kustomizations.
- **Infrastructure as Code**: Infrastructure and apps are defined in `infrastructure/` and `apps/` using native Kustomize manifests.

## 🔐 Secret Management

We maintain a strict distinction between developer and service secrets:

- **Developer Secrets**: Managed as local environment variables (e.g., in a `.env` file or shell session). these are for tools interacting with the cluster or external APIs.
- **Service Secrets**: Encrypted via `sops` (`.sops.yaml`) directly in the git repository. Flux handles decryption during reconciliation.

## 🛠️ Getting Started

### 1. Environment Setup

Ensure you have `docker`, `sops`, and `trunk` installed.

### 2. Management Tools

- `docker`: Directly interact with the Swarm manager.
- `sops`: For secret encryption/decryption (requires a configured age key).
- [trunk](https://trunk.io): For linting and formatting compliance across the repository.

---

For detailed contribution guidelines, see [**`CONTRIBUTING.md`**](CONTRIBUTING.md).
For AI Agent specific context, see [**`AGENTS.md`**](AGENTS.md).

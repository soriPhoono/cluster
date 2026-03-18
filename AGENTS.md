# AI Agent Guidelines for the Data Fortress

Welcome! This document provides essential context, architectural rules, and defined workflows to help AI agents navigate and contribute to the **Data Fortress** repository effectively.

## 🤖 Agent-First Philosophy

This project is designed with **Agent-First** automation in mind. The repository acts as a "Bootstrap Black Box" — once initialized, it is intended to be managed and scaled autonomously through GitOps and CI/CD pipelines.

## 🏗️ Architectural Constraints

When modifying or adding workloads to this repository, agents **MUST** adhere to these rules:

1.  **Image Pinning**: Always use a specific version tag or digest. Never use `latest`.
2.  **GitOps Driven**: All configuration must be defined declaratively in this repository and reconciled by **FluxCD**. Manual cluster changes are strictly forbidden.
3.  **Namespace Isolation**: Workloads must be grouped logically into namespaces, typically defined in `infrastructure/base/namespaces`.
4.  **Kustomize**: Rely primarily on Kustomize to structure and combine manifests (e.g. `apps/base/` and `apps/production/`).

## 🔐 Secret Management Archetypes

Agents must understand the two distinct archetypes for secrets:

### 1. Developer Environment Secrets

- Used for human/agent tool usage (e.g., repository API tokens, management keys).
- **Consumption**: Managed as local environment variables (e.g., in a `.env` file or shell session).

### 2. Service/Runtime Secrets (**SOPS**)

- Used for Kubernetes workloads at runtime.
- **Storage**: Encrypted using **SOPS** (`.sops.yaml`) directly in the git repository. FluxCD handles decryption on the cluster side during reconciliation.

## 🛠️ Essential Agent Tools

Pre-configured tools that agents should leverage:

- **`kubectl` / `k9s`**: Primary interface for visualizing cluster state.
- **`flux`**: The GitOps controller used for bootstrapping and reconciling. Example components include `kustomizations` in `clusters/homelab/`.
- **`kustomize`**: Used heavily to assemble the YAML structures.
- **`sops`**: Used for editing and rotating service secrets within the repository structure.

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

The Data Fortress has transitioned to a fully declarative **K3s Kubernetes** environment driven by **FluxCD**, running on a unified EndeavourOS workstation and x86 mini-PC Edge tier.

# Cluster GitOps

Catch-all gitops target for deploying stacks and services across multiple orchestration platforms.

## Supported Platforms

| Platform | GitOps Engine |
|----------|---------------|
| k3s clusters | FluxCD |
| Docker Swarm clusters | SwarmCD |
| Docker Compose servers | Portainer GitOps |

## Getting Started

```bash
direnv allow   # auto-load dev shell
nix develop    # enter development environment
```

## Commands

```bash
nix develop    # enter dev shell
nix fmt        # format all files
nix build .#k3s.${clusterName}     # build the flake for a specific cluster
nix build .#swarm.${swarmName}     # build the flake for a specific swarm
nix build .#compose.${serverName}     # build the flake for a specific server
```

## Tools

- **nixd** - Nix language server
- **alejandra** - Nix formatter
- **deadnix** / **statix** - Nix linting
- **gitleaks** - Secrets detection

## Structure

This repository serves as the single source of truth for all cluster deployments. Each directory typically represents a namespace, workload, or environment depending on the target platform.

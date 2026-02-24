# Initial Concept

A self-hosted Kubernetes home lab cluster managed with Nix and Talos Linux, focusing on reproducibility, declarative configuration, and secure secret management.

# Product Guide

## Vision

To provide a rock-solid, reproducible, and fully declarative home server infrastructure that serves as a reliable foundation for self-hosted services, experimentation, and learning.

## Target Users

- Home lab enthusiasts and self-hosters.
- Developers looking for a production-like environment for testing.
- Systems administrators interested in Infrastructure as Code (IaC) and immutable operating systems.

## Core Features

- **Reproducible Environment**: Entire toolchain and environment managed by Nix Flakes.
- **Immutable Infrastructure**: Kubernetes nodes running on Talos Linux, managed via API.
- **Declarative Orchestration**: All workloads defined as Kubernetes manifests.
- **Secure Secret Management**: SOPS and age integration for encrypting secrets in-repo.
- **Automated Quality Checks**: Pre-commit hooks for linting, formatting, and manifest validation.

## Success Criteria

- Cluster nodes can be easily provisioned and updated using declarative configs.
- Manifests pass validation and adhere to strict pinning and resource limit rules.
- Services are resilient, with properly configured probes and resource allocations.

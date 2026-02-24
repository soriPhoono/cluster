# Specification - FluxCD and Helm Integration

## Goal

Implement FluxCD as the GitOps operator for the cluster, enabling automated deployments of Kubernetes manifests and Helm charts directly from this repository.

## Requirements

- Install FluxCD controllers (source-controller, helm-controller, kustomize-controller, notification-controller).
- Configure a GitRepository source pointing to this repository.
- Enable Helm support through HelmRepository and HelmRelease custom resources.
- Integrate with existing SOPS/age secret management for secure credential handling.
- Adhere to the cluster's manifest requirements (pinning, validation, healthchecks).

## Technical Architecture

- **FluxCD**: Deployed in the `flux-system` namespace.
- **Bootstrap**: Use the Flux CLI for initial setup, then manage via declarative manifests in `k8s/core/flux-system/`.
- **Helm Support**: Define `HelmRepository` for upstream charts and `HelmRelease` for deployments.
- **Secrets**: Use the existing SOPS/age setup to provide Git credentials to Flux if necessary.

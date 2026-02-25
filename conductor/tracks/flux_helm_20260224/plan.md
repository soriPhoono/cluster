# Implementation Plan - FluxCD and Helm Integration

## Phase 1: FluxCD Core Infrastructure

- [x] Task: Prepare FluxCD bootstrap manifests
  - [x] Generate bootstrap manifests using Flux CLI
  - [x] Review and adapt manifests to follow project pinning and resource rules
- [x] Task: Deploy FluxCD to the cluster
  - [x] Apply bootstrap manifests to the `flux-system` namespace
  - [x] Verify all controllers (source, helm, kustomize) are healthy
- [~] Task: Conductor - User Manual Verification 'Phase 1: FluxCD Core Infrastructure' (Protocol in workflow.md)

## Phase 2: GitOps Source Configuration

- [x] Task: Configure GitRepository for this repo
  - [x] Write validation test (kubeconform) for the GitRepository manifest
  - [x] Implement GitRepository manifest in `k8s/core/flux-system/gotk-sync.yaml`
- [x] Task: Configure SOPS integration for Flux
  - [x] Write tests to verify SOPS secret decryption capability
  - [x] Deploy SOPS/age secret to Flux system to allow decryption of in-repo secrets
- [~] Task: Conductor - User Manual Verification 'Phase 2: GitOps Source Configuration' (Protocol in workflow.md)

## Phase 3: Helm Support Integration

- [x] Task: Configure HelmRepository support
  - [x] Write validation tests for HelmRepository CRD usage
  - [x] Implement an example HelmRepository (e.g., bitnami) to verify connectivity
- [x] Task: Implement HelmRelease workflow
  - [x] Create a template for HelmRelease manifests following project standards
  - [x] Verify Flux can successfully deploy a sample Helm chart
- [~] Task: Conductor - User Manual Verification 'Phase 3: Helm Support Integration' (Protocol in workflow.md)

## Description

Please include a summary of the change and which issue is fixed. Please also include relevant motivation and context.

Fixes # (issue)

## Type of change

Please delete options that are not relevant.

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Infrastructure change (updating Nix, Talos, or Kubernetes manifests)
- [ ] Documentation update

## How Has This Been Tested?

Please describe the steps taken to verify your changes. Where possible, test against the `testing` cluster before targeting `adams`.

- [ ] Ran `kubeconform` against changed manifests
- [ ] Verified Flux reconciliation (`flux reconcile kustomization <name> --with-source`)
- [ ] Verified deployment on cluster (node / namespace):

## Checklist

- [ ] My changes follow the style guidelines of this project
- [ ] I have performed a self-review of my own changes
- [ ] I have commented any manifests with non-obvious configuration choices
- [ ] I have updated documentation accordingly (e.g. `README.md`, `AGENTS.md`)
- [ ] All manifests satisfy the Kubernetes strict requirements (image pinning, resource limits, health checks, encrypted secrets)

______________________________________________________________________

## description: How to create and configure a new Kubernetes workload

# Workflow: Create a New Kubernetes Workload

This workflow defines the exact steps an agent should take when a user asks to add a new service or workload to the Kubernetes cluster. Always follow these steps strictly to ensure compliance with the repository's configuration standards.

## 1. Create the Manifest Directory

Determine the category of the new workload (e.g., `core`, `databases`, `media-stack`, `security`).
Create a dedicated directory under `k8s/<category>/<workload_name>`.

```bash
mkdir -p k8s/<category>/<workload_name>
```

## 2. Create the Declarative Manifests

Create the standard Kubernetes YAML files inside the newly created directory. This often includes `deployment.yaml`, `service.yaml`, and `ingress.yaml`.

The most critical part of this step is ensuring the manifests abide by the **Strict Kubernetes Requirements**.

### Strict Kubernetes Requirements Checklist:

- [ ] **Image Pinning**: Use a specific tag or digest, never `latest`.
- [ ] **Declarative Configuration**: All configurations must be committed as YAML files.
- [ ] **Healthchecks**: Establish `livenessProbe` and `readinessProbe` on containers to handle routing correctly.
- [ ] **Secrets & Configs**: Do not supply plain text secrets in manifests. If a user provides a secret, advise them to use `sops` with `age` to encrypt it before committing.
- [ ] **Resource Limits**: Define both `requests` and `limits` (CPU and Memory) for predictability.
- [ ] **Validation**: Ensure `kubeconform` passes via `pre-commit run --all-files`.

## 3. Final Review

1. Validate the manifests with `pre-commit run --all-files` automatically.
1. Ask the user if they'd like help applying the configuration (e.g., via `kubectl apply`) or if they just want a PR opened for the configuration addition.

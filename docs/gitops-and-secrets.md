# GitOps and secrets

**Status:** Deployed
**Scope:** Encrypting cluster manifests under `k3s/` and developer-only secrets used by the Nix flake.

## Cluster secrets (SOPS + Flux)

- Manifest paths under `k3s/` should be encrypted with **SOPS**. Key selection follows [`.sops.yaml`](../.sops.yaml) at the repository root (including [`../k3s/infrastructure/cloudflare/*.sops.yaml`](../k3s/infrastructure/cloudflare), where only `stringData` / `data` are encrypted).
- Flux decrypts using the **`sops-age`** secret in `flux-system` (created before or during bootstrap; see the `nix run` deploy script in [`../flake.nix`](../flake.nix) for the testing cluster).

Example workflow:

```bash
kubectl create secret generic my-secret \
  --from-literal=key=value \
  --dry-run=client -o yaml > k3s/infrastructure/controllers/my-secret.sops.yaml
sops -e -i k3s/infrastructure/controllers/my-secret.sops.yaml
```

Reference the encrypted file from a `Kustomization` that Flux applies (for example under `k3s/infrastructure/controllers`).

## Developer secrets (agenix / age)

For secrets that **must not** ship to the cluster but are needed locally (tokens, age keys), encrypt with **age** and wire them through **agenix-shell** in the flake. Example encrypt command:

```bash
age -e -i ~/.ssh/id_ed25519 -o secret.age plaintext.txt
```

To expose a decrypted value inside `nix develop`, extend `agenix-shell` in [`../flake.nix`](../flake.nix) (see existing `secrets` entries such as `GITHUB_TOKEN` and `TESTING_AGE_KEY`).

## Upstream

- [Flux SOPS integration](https://fluxcd.io/flux/guides/mozilla-sops/)
- [SOPS](https://github.com/getsops/sops)

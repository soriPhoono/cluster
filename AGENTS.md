# AGENTS.md

This is a Nix flake project.

## Dev environment

```bash
direnv allow   # auto-loads flake devShell via .envrc
```

## Commands

```bash
nix develop                  # enter dev shell
nix fmt                      # run treefmt (all formatters)
nix run                      # deploy a testing cluster, install the testing cluster key if authorized, then deploy the cluster stack using flux-cd
```

## Tools

- **nixd** - Nix language server (installed in devShell)
- **alejandra** - Nix formatter
- **deadnix** - Nix dead code detector
- **statix** - Nix linter
- **gitleaks** - secrets scanner (pre-commit hook)

## Pre-commit

Hooks run automatically on commit via git-hooks-nix. Manual run:

```bash
nix develop -c pre-commit run --all-files
```

## Cursor Cloud specific instructions

- The Nix daemon must be running before any `nix` commands. The update script starts it automatically. If commands fail with "error connecting to daemon", run `sudo /nix/var/nix/profiles/default/bin/nix-daemon &` and wait 2 seconds.
- The agenix-shell hook errors (decrypting `GITHUB_TOKEN` / `TESTING_AGE_KEY`) are expected in Cloud Agent VMs because the developer's SSH identity key is not present. All dev shell tools still work; only `nix run` (deploy) is affected.
- Create `/agenix-shell` with `sudo mkdir -p /agenix-shell && sudo chmod 777 /agenix-shell` before entering the dev shell, or the hook will fail with a permission error instead of the harmless identity warning.
- `nix fmt -- --fail-on-change` is the correct way to check formatting (not `--check`). The treefmt version bundled uses `--fail-on-change` and `--ci` flags.
- `deadnix` and `statix` are not on PATH directly; they run through `nix fmt` (treefmt) and pre-commit hooks.
- **k3d / k3s clusters cannot run** in the Cloud Agent VM. The nested container environment (Docker-in-Docker inside Firecracker) lacks cgroup v2 memory controller delegation. k3s exits with `failed to find memory cgroup (v2)`. This means `nix run` (deploy) will not work. All other dev tasks (formatting, linting, editing manifests, pre-commit checks) work normally.
- Docker is installed and functional for general container operations; only k3s-specific cgroup requirements are unsatisfied.

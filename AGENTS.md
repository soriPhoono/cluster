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

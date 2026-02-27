{
  description = "Cluster management flake";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs-weekly.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1.948651";

    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
    agenix-shell = {
      url = "github:aciceri/agenix-shell";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
    github-actions-nix = {
      url = "github:synapdeck/github-actions-nix";
      inputs.nixpkgs.follows = "nixpkgs-weekly";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs-weekly,
    flake-parts,
    agenix,
    agenix-shell,
    treefmt-nix,
    git-hooks-nix,
    github-actions-nix,
    ...
  }: let
    # Extend lib with our custom functions
    lib = nixpkgs-weekly.lib.extend (
      final: prev:
        (import ./lib/default.nix {inherit inputs;}) final prev
    );

    supportedSystems = import inputs.systems;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
        github-actions-nix.flakeModule
      ];

      systems = supportedSystems;

      agenix-shell.secrets = (import ./secrets.nix {inherit lib;}).agenix-shell-secrets;

      perSystem = {
        pkgs,
        config,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs-weekly {
          inherit system;
          overlays = [
            (_: _: {
              agenix = agenix.packages.${system}.default;
            })
          ];
          config.allowUnfree = true;
        };

        checks = lib.discoverTests {inherit pkgs;} ./tests;
        githubActions = import ./actions.nix {inherit self lib;};

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit agenix-shell githubActions;
          };
        };

        apps = {
          unseal = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "unseal.sh";
              runtimeInputs = with pkgs; [
                talosctl
                kubectl
                fluxcd
              ];
              text = ''
                sops --decrypt --in-place ./talos/talosconfig
                sops --decrypt --in-place ./talos/controlplane.yaml
                sops --decrypt --in-place ./talos/worker.yaml
              '';
            }}/bin/unseal.sh";
          };
          seal = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "seal.sh";
              runtimeInputs = with pkgs; [
                git

                sops

                talosctl
                kubectl
                fluxcd
              ];
              text = ''
                sops --encrypt --in-place ./talos/talosconfig
                sops --encrypt --in-place ./talos/controlplane.yaml
                sops --encrypt --in-place ./talos/worker.yaml
              '';
            }}/bin/seal.sh";
          };
          test-blackbox = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "launch-development-cluster.sh";
              runtimeInputs = with pkgs; [
                talosctl
                kubectl
                fluxcd
              ];
              text = ''
                # 1. Check if talosconfig exists (optional but recommended)
                if [[ -z "$TALOSCONFIG" ]]; then
                  export TALOSCONFIG="$HOME/.talos/config"
                fi

                QEMU_RUNNING=$(pgrep -f "qemu-system-x86_64.*talos" || true)

                # If there are no qemu PIDs with talos
                if [ -z "$QEMU_RUNNING" ]; then
                  echo "No talos containers found. Creating a new cluster..."
                  sudo -E talosctl cluster create qemu

                  if [ -z "$GITHUB_TOKEN" ]; then
                    echo "WARNING: GITHUB_TOKEN not found. flux bootstrap may fail if token-auth is required."
                  fi

                  echo "Cluster created successfully, initializing FluxCD inside newly created docker cluster"
                  flux bootstrap github \
                    --token-auth \
                    --owner=soriPhoono \
                    --repository=cluster \
                    --branch="$(git rev-parse --abbrev-ref HEAD)" \
                    --path=k8s/clusters/testing/ \
                    --personal --verbose

                  if [ -n "$CLUSTER_AGE_KEY" ]; then
                    echo "Found CLUSTER_AGE_KEY, injecting sops-age secret..."
                    echo "$CLUSTER_AGE_KEY" | kubectl create secret generic sops-age \
                      --namespace=flux-system \
                      --from-file=age.agekey=/dev/stdin \
                      --dry-run=client -o yaml | kubectl apply -f -
                  else
                    echo "WARNING: CLUSTER_AGE_KEY not found. SOPS decryption may fail in-cluster."
                  fi
                else
                  echo "Found existing docker cluster, not overwriting..."
                fi

                if talosctl health --wait-timeout 5s >/dev/null 2>&1; then
                  echo "Result: Talos QEMU Cluster is UP and AVAILABLE."
                else
                  echo "Result: QEMU is running, but the Talos API is UNREACHABLE."
                  exit 1
                fi
              '';
            }}/bin/launch-development-cluster.sh";
          };
        };

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
      };
    };
}

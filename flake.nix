{
  description = "Empty flake template";

  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix-shell = {
      url = "github:aciceri/agenix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    # --- System Support & Package Cache --- #
    systems = import inputs.systems;

    lib = nixpkgs.lib.extend (import ./nix/lib.nix);
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];

      inherit systems;

      agenix-shell = {
        identityPaths = [
          "$HOME/.ssh/id_ed25519"
        ];
        secrets = {
          GITHUB_TOKEN.file = ./secrets/github_token.age;
          TESTING_AGE_KEY.file = ./secrets/testing_age_key.age;
        };
      };

      perSystem = {
        pkgs,
        config,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit agenix-shell;
          };
        };

        # --- Configuration Builders --- #
        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};

        apps = rec {
          deploy = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "deploy";
              text = ''
                set -euo pipefail

                CLUSTER_NAME=k3d-guenivir-testing

                echo "Deleting old cluster..."
                echo "----------------------------------------"
                k3d cluster delete "$CLUSTER_NAME" || true

                echo "Creating cluster..."
                echo "----------------------------------------"

                k3d cluster create \
                  --k3s-arg '--disable=traefik@server:*' \
                  --servers 1 \
                  --agents 2 \
                  --image rancher/k3s:v1.31.5-k3s1 \
                  --wait \
                  --timeout 120s \
                  "$CLUSTER_NAME" || (k3d cluster delete "$CLUSTER_NAME")

                sleep 2

                echo "Preparing namespace and SOPS key (before Flux sync applies SOPS kustomizations)..."
                echo "----------------------------------------"
                kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
                kubectl create secret generic sops-age \
                  --namespace=flux-system \
                  --from-file=age.agekey="$TESTING_AGE_KEY_PATH" \
                  --dry-run=client -o yaml | kubectl apply -f -

                echo "Deploying Flux to testing cluster..."
                echo "----------------------------------------"
                flux bootstrap github \
                  --owner=soriphoono \
                  --repository=cluster \
                  --branch="$(git rev-parse --abbrev-ref HEAD)" \
                  --path=k3s/clusters/testing \
                  --personal \
                  --token-auth || (k3d cluster delete "$CLUSTER_NAME")

                echo "Done!"
                echo "----------------------------------------"
              '';
            }}/bin/deploy";
          };
          default = deploy;
        };
      };
    };
}

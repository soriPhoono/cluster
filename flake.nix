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
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
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
        mcp-servers-nix.flakeModule
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
            inherit (config) pre-commit agenix-shell mcp-servers;
          };
        };

        # --- Configuration Builders --- #
        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
        mcp-servers = import ./mcp.nix {inherit lib pkgs;};

        apps = rec {
          deploy = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "deploy";
                runtimeInputs = [
                  pkgs.k3d
                  pkgs.kubectl
                  pkgs.kubernetes-helm
                  pkgs.fluxcd
                  pkgs.git
                  pkgs.gh
                ];
                text = ''
                  set -euo pipefail

                  CLUSTER_NAME=k3d-guenivir-testing

                  function operation() {
                    message="$1"
                    error_message="$2"
                    command="$3"

                    echo "$message"
                    echo "----------------------------------------"
                    sh -c "$command"

                    local status=$?
                    if [ $status -ne 0 ]; then
                      echo "$error_message"
                      k3d cluster delete "$CLUSTER_NAME"
                      echo "Cluster deleted with status $status"
                      exit $status
                    fi
                  }

                  # gh requires $HOME to find its auth config
                  export HOME="$HOME"

                  operation "Deleting old cluster..." "Failed to delete cluster" "k3d cluster delete '$CLUSTER_NAME' || true"

                  sleep 2

                  operation "Creating cluster..." "Failed to create cluster" "k3d cluster create --k3s-arg '--disable=traefik@server:*' --image rancher/k3s:v1.31.5-k3s1 --wait --timeout 120s '$CLUSTER_NAME'"

                  sleep 2

                  operation "Preparing namespace and SOPS key (before Flux sync applies SOPS kustomizations)..." "Failed to prepare namespace and SOPS key" "kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -"
                  operation "Creating secret sops-age..." "Failed to create secret sops-age" "kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=$HOME/.config/sops/age/keys.txt --dry-run=client -o yaml | kubectl apply -f -"

                  operation "Deploying Flux to testing cluster..." "Failed to deploy Flux" "gh auth token | flux bootstrap github --owner=soriphoono --repository=guenivir --branch='$(git rev-parse --abbrev-ref HEAD)' --path=k3s/clusters/testing --personal --token-auth"

                  echo "Done!"
                  echo "----------------------------------------"
                '';
              }
            }/bin/deploy";
          };
          default = deploy;
        };
      };
    };
}

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
                k3d cluster create \
                  --k3s-arg '--disable=traefik@server:*' \
                  --servers 1 \
                  --agents 2 \
                  --image rancher/k3s:v1.31.5-k3s1 \
                  --wait \
                  --timeout 120s \
                  k3d-testing

                flux bootstrap github \
                  --owner=soriphonoo \
                  --repository=cluster \
                  --branch="$(git rev-parse --abbrev-ref HEAD)" \
                  --path=k3s/clusters/testing \
                  --personal \
                  --token-auth
              '';
            }}/bin/deploy";
          };
          default = deploy;
        };
      };
    };
}

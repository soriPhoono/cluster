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
  };

  outputs = inputs @ {
    nixpkgs-weekly,
    flake-parts,
    agenix,
    agenix-shell,
    treefmt-nix,
    git-hooks-nix,
    ...
  }: let
    # Extend lib with our custom functions
    inherit (nixpkgs-weekly) lib;

    supportedSystems = import inputs.systems;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
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

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit agenix-shell githubActions;
          };
        };

        # apps = lib.discoverApps {inherit pkgs;} ./scripts;

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
      };
    };
}

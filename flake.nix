{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];
      systems = with inputs; import systems;
      perSystem = {
        pkgs,
        config,
        lib,
        ...
      }:
        with pkgs;
        with lib; rec {
          devShells.default = mkShell {
            shellHook = ''
              ${config.pre-commit.shellHook}
            '';
          };

          treefmt.programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;

            yamlfmt.enable = true;
          };

          pre-commit = {
            check.enable = true;
            settings.hooks = {
              nil.enable = true;

              treefmt.enable = true;
            };
          };
        };
    };
}

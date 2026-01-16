{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }: flake-utils.lib.eachDefaultSystem (system: let 
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells = rec {
      dev = pkgs.mkShell {
        packages = with pkgs; [
          talosctl
        ];
      };
      default = dev;
    };
  });
}

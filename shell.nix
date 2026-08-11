{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      gh

      nixd
      nil
      alejandra

      age
      sops
      secretspec

      # age
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

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
      secretspec

      # age
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

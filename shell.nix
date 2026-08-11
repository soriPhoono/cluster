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

      # terraform
      terraform
      tfsec
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

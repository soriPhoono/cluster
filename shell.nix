{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nil
      alejandra

      age
      sops
      ssh-to-age
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

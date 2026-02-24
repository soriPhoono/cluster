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

      talosctl
      kubectl
      fluxcd
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

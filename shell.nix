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
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

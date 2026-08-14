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

      # kubernetes
      kubectl

      # talos linux
      talosctl
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      ${pkgs.talosctl}/bin/talosctl completion fish | source
    '';
  }

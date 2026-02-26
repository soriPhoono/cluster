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
      agenix
      sops
      ssh-to-age

      talosctl
      kubectl
      kubernetes-helm
      fluxcd
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      # TODO: Add dynamic generation of devShell GitHub Actions workflow files from ./actions.nix
    '';
  }

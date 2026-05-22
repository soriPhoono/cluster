{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nil
      nixd
      alejandra

      age
      sops
      ssh-to-age

      jq
      yq

      k3d
      kubectl
      kubernetes-helm
      fluxcd
      k9s
    ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}
    '';
  }

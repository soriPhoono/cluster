{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nixd
      alejandra

      age
      agenix-cli
      ssh-to-age
      sops

      jq
      yq

      k3d
      kubectl
      helm
      k9s
      fluxcd
    ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}
    '';
  }

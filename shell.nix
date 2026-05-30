{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    inputsFrom = [
      config.mcp-servers.devShell
    ];

    packages = [
      gh

      nixd
      nil
      alejandra

      age
      sops
      ssh-to-age

      jq
      yq

      k0sctl
      kubectl
      kubernetes-helm
      fluxcd
      k9s

      google-cloud-sdk
    ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}
    '';
  }

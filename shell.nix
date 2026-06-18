{
  inputs,
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
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      sops
      ssh-to-age

      jq
      yq

      kubectl
      kind
      k9s

      fluxcd
      flux9s
      fluxcd-operator
      fluxcd-operator-mcp

      terraform
    ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}
    '';
  }

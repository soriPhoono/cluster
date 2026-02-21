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
      agenix

      terraform

      kubectl
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      alias s="sops"

      export TF_VAR_proxmox_api_secret="$PROXMOX_API_SECRET"
    '';
  }

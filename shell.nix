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

    TF_VAR_proxmox_api_url = "https://pve-dev.xerus-augmented.ts.net";
    TF_VAR_cluster_name = "staging";

    shellHook = ''
      ${config.pre-commit.shellHook}

      ${pkgs.talosctl}/bin/talosctl completion fish | source
    '';
  }

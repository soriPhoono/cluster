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

      # YAML and Kubernetes validation
      yamllint
      kubernetes-validate
      kube-linter

      # kubernetes
      kubectl
      k9s
      kubernetes-helm
      fluxcd
      flux9s

      # talos linux
      talosctl
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      ${pkgs.talosctl}/bin/talosctl completion fish | source
    '';
  }

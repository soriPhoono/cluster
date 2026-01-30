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
      agenix
      fluxcd
      kubectl
      kubernetes-helm
      kustomize
      sops
      age
      kubeconform
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }

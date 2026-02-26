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

      # If there are no docker containers with talos
      if [ -z "$(docker ps --filter "name=talos-default" --format "{{.Names}}")" ]; then
        echo "No talos containers found. Creating a new cluster..."
        talosctl cluster create docker

        echo "Cluster created successfully, initializing FluxCD inside newly created docker cluster"
        flux bootstrap github \
          --token-auth \
          --owner=soriPhoono \
          --repository=cluster \
          --branch=main \
          --path=k8s/clusters/testing/ \
          --personal --verbose
      else
        echo "Found existing docker cluster, not overwriting..."
      fi
    '';
  }

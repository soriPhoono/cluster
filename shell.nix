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

        if [ -z "$GITHUB_TOKEN" ]; then
          echo "WARNING: GITHUB_TOKEN not found. flux bootstrap may fail if token-auth is required."
        fi

        echo "Cluster created successfully, initializing FluxCD inside newly created docker cluster"
        flux bootstrap github \
          --token-auth \
          --owner=soriPhoono \
          --repository=cluster \
          --branch=$(git rev-parse --abbrev-ref HEAD) \
          --path=k8s/clusters/testing/ \
          --personal --verbose

        if [ -n "$CLUSTER_AGE_KEY" ]; then
          echo "Found CLUSTER_AGE_KEY, injecting sops-age secret..."
          echo "$CLUSTER_AGE_KEY" | kubectl create secret generic sops-age \
            --namespace=flux-system \
            --from-file=age.agekey=/dev/stdin \
            --dry-run=client -o yaml | kubectl apply -f -
        else
          echo "WARNING: CLUSTER_AGE_KEY not found. SOPS decryption may fail in-cluster."
        fi
      else
        echo "Found existing docker cluster, not overwriting..."
      fi
    '';
  }

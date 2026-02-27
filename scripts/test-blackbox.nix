{pkgs, ...}: {
  type = "app";
  program = "${pkgs.writeShellApplication {
    name = "launch-development-cluster.sh";
    runtimeInputs = with pkgs; [
      talosctl
      kubectl
      fluxcd
    ];
    text = ''
      QEMU_RUNNING=$(pgrep -f "qemu-system-x86_64.*talos" || true)

      # If there are no qemu PIDs with talos
      if [ -z "$QEMU_RUNNING" ]; then
        echo "No talos containers found. Creating a new cluster..."
        sudo -E talosctl cluster create qemu

        if [ -z "$GITHUB_TOKEN" ]; then
          echo "WARNING: GITHUB_TOKEN not found. flux bootstrap may fail if token-auth is required."
        fi

        echo "Cluster created successfully, initializing FluxCD inside newly created docker cluster"
        flux bootstrap github \
          --token-auth \
          --owner=soriPhoono \
          --repository=cluster \
          --branch="$(git rev-parse --abbrev-ref HEAD)" \
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

      if talosctl health --wait-timeout 5s >/dev/null 2>&1; then
        echo "Result: Talos QEMU Cluster is UP and AVAILABLE."
      else
        echo "Result: QEMU is running, but the Talos API is UNREACHABLE."
        exit 1
      fi
    '';
  }}/bin/launch-development-cluster.sh";
}

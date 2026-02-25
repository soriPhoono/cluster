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

      talosctl
      kubectl
      fluxcd
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      # Automation: Ensure test cluster exists at session start
      if ! docker ps --format "{{.Names}}" | grep -q "talos-default"; then
        echo "[INFO]: No Talos test cluster detected. Initializing..."
        ./scripts/setup-test-cluster.sh
      else
        echo "[INFO]: Talos test cluster already running."
        # Ensure KUBECONFIG is set if the file exists
        if [ -f "./kubeconfig" ]; then
          export KUBECONFIG="$(pwd)/kubeconfig"
        fi
      fi
    '';
  }

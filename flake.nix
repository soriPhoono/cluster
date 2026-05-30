{
  description = "Guenivir — multi-cluster Kubernetes GitOps";

  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix-shell = {
      url = "github:aciceri/agenix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    # --- System Support & Package Cache --- #
    systems = import inputs.systems;

    lib = nixpkgs.lib.extend (import ./nix/lib.nix);
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
        mcp-servers-nix.flakeModule
      ];

      inherit systems;

      agenix-shell = {
        identityPaths = [
          "$HOME/.ssh/id_ed25519"
        ];
        secrets = {
          GITHUB_TOKEN.file = ./secrets/github_token.age;
          TESTING_AGE_KEY.file = ./secrets/testing_age_key.age;
        };
      };

      perSystem = {
        pkgs,
        config,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit agenix-shell mcp-servers;
          };
        };

        # --- Configuration Builders --- #
        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
        mcp-servers = import ./mcp.nix {inherit lib pkgs;};

        apps = rec {
          deploy = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "deploy";
                runtimeInputs = [
                  pkgs.k0sctl
                  pkgs.kubectl
                  pkgs.kubernetes-helm
                  pkgs.fluxcd
                  pkgs.git
                  pkgs.gh
                ];
                text = ''
                  set -euo pipefail

                  CLUSTER_NAME=k0s-guenivir-testing
                  K0S_IMAGE=docker.io/k0sproject/k0s:v1.35.3-k0s.0

                  function operation() {
                    message="$1"
                    error_message="$2"
                    command="$3"

                    echo
                    echo "$message"
                    echo "----------------------------------------"
                    sh -c "$command"

                    local status=$?
                    if [ $status -ne 0 ]; then
                      echo "$error_message"
                      docker rm -f "$CLUSTER_NAME" 2>/dev/null || true
                      echo "Cluster removed with status $status"
                      exit $status
                    fi
                  }

                  # gh requires $HOME to find its auth config
                  export HOME="$HOME"

                  # ---- Phase 1: Clean up any previous k0s container ----
                  operation "Removing old k0s container..." "Failed to remove old container" "docker rm -f '$CLUSTER_NAME' 2>/dev/null || true"

                  sleep 2

                  # ---- Phase 2: Start k0s in Docker ----
                  operation "Starting k0s cluster in Docker..." "Failed to start k0s" "docker run -d --name '$CLUSTER_NAME' --hostname '$CLUSTER_NAME' --privileged -v /var/lib/k0s -v /var/log/pods --tmpfs /run -p 6443:6443 '$K0S_IMAGE'"

                  echo "Waiting for k0s API server to be ready..."
                  # Wait until the kubeconfig is available inside the container
                  for i in $(seq 1 30); do
                    if docker exec "$CLUSTER_NAME" k0s kubeconfig admin > /dev/null 2>&1; then
                      echo "k0s API ready after $i"s
                      break
                    fi
                    if [ "$i" -eq 30 ]; then
                      echo "k0s API did not become ready in time"
                      exit 1
                    fi
                    sleep 2
                  done

                  # ---- Phase 3: Extract and fix kubeconfig for local access ----
                  echo "Extracting kubeconfig..."
                  docker exec "$CLUSTER_NAME" k0s kubeconfig admin > /tmp/k0s-kubeconfig
                  # Replace the internal IP with localhost so kubectl works from the host
                  sed -i "s|https://.*:6443|https://localhost:6443|" /tmp/k0s-kubeconfig
                  export KUBECONFIG=/tmp/k0s-kubeconfig

                  echo "Waiting for k0s node to register and become ready..."
                  for i in $(seq 1 90); do
                    if kubectl get nodes 2>/dev/null | grep -q Ready; then
                      echo "Node ready after $i"s
                      break
                    fi
                    if [ "$i" -eq 90 ]; then
                      echo "Node did not become ready in time"
                      kubectl get nodes 2>/dev/null || true
                      exit 1
                    fi
                    sleep 2
                  done

                  # k0s applies control-plane:NoSchedule taint even with --enable-worker
                  # Remove it so pods can schedule on the single node
                  kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule- 2>/dev/null || true
                  echo "Removed control-plane taint to allow workload scheduling"

                  # ---- Phase 4: Prepare Flux bootstrap ----
                  operation "Preparing namespace and SOPS key (before Flux sync applies SOPS kustomizations)..." "Failed to prepare namespace and SOPS key" "kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -"
                  operation "Creating secret sops-age..." "Failed to create secret sops-age" "kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=$HOME/.config/sops/age/keys.txt --dry-run=client -o yaml | kubectl apply -f -"

                  # ---- Phase 5: Bootstrap Flux ----
                  # Use GITHUB_TOKEN env var if set, otherwise fall back to gh auth token
                  if [ -n "$GITHUB_TOKEN" ]; then
                    export FLUX_TOKEN="$GITHUB_TOKEN"
                  else
                    export FLUX_TOKEN="$(gh auth token)"
                  fi
                  echo "$FLUX_TOKEN" | flux bootstrap github \
                    --owner=soriPhoono \
                    --repository=guenivir \
                    --branch="$(git rev-parse --abbrev-ref HEAD)" \
                    --path=k8s/clusters/testing \
                    --personal \
                    --token-auth

                  echo "Done!"
                  echo "----------------------------------------"
                  echo ""
                  echo "To interact with the cluster:"
                  echo "  export KUBECONFIG=/tmp/k0s-kubeconfig"
                  echo "  kubectl get nodes"
                  echo ""
                  echo "To tear down:"
                  echo "  docker rm -f $CLUSTER_NAME"
                '';
              }
            }/bin/deploy";
          };
          default = deploy;
        };
      };
    };
}

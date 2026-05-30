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

                  # ---- Phase 3: Extract and persist kubeconfig ----
                  echo "Extracting kubeconfig..."
                  mkdir -p ~/.kube
                  K8S_KUBECONFIG="$HOME/.kube/k0s-guenivir-testing.config"
                  CONTEXT_NAME="k0s-guenivir-testing"

                  # Extract kubeconfig from k0s and fix server address
                  docker exec "$CLUSTER_NAME" k0s kubeconfig admin \
                    | sed "s|https://.*:6443|https://localhost:6443|" \
                    > "$K8S_KUBECONFIG"

                  # Normalize the context/cluster/user names to well-known values
                  OLD_CONTEXT=$(kubectl config view --kubeconfig="$K8S_KUBECONFIG" -o=jsonpath='{.contexts[0].name}' 2>/dev/null || echo "")
                  if [ -n "$OLD_CONTEXT" ] && [ "$OLD_CONTEXT" != "$CONTEXT_NAME" ]; then
                    kubectl config rename-context "$OLD_CONTEXT" "$CONTEXT_NAME" \
                      --kubeconfig="$K8S_KUBECONFIG" >/dev/null 2>&1 || true
                  fi

                  # Merge into the main kubeconfig so kubectl works immediately
                  # and persists across shell sessions
                  if [ -f ~/.kube/config ]; then
                    cp ~/.kube/config ~/.kube/config.bak
                  fi
                  export KUBECONFIG="$HOME/.kube/config:$K8S_KUBECONFIG"
                  kubectl config view --flatten > /tmp/k0s-merged-config
                  mv /tmp/k0s-merged-config ~/.kube/config

                  # Activate the cluster context
                  kubectl config use-context "$CONTEXT_NAME" >/dev/null 2>&1 || true
                  export KUBECONFIG="$HOME/.kube/config"

                  echo "Waiting for k0s node to register..."
                  for i in $(seq 1 60); do
                    if kubectl get nodes -o name 2>/dev/null | grep -q node; then
                      echo "Node registered after $i"s
                      break
                    fi
                    if [ "$i" -eq 60 ]; then
                      echo "Node did not register in time"
                      kubectl get nodes 2>/dev/null || true
                      docker logs "$CLUSTER_NAME" --tail=10 2>/dev/null || true
                      exit 1
                    fi
                    sleep 2
                  done

                  echo "Waiting for node to become Ready..."
                  kubectl wait --for=condition=Ready node --all --timeout=180s 2>/dev/null || true
                  # Give it one more chance with a loop if kubectl wait failed
                  for i in $(seq 1 30); do
                    if kubectl get nodes 2>/dev/null | grep -q Ready; then
                      echo "Node ready after waiting"
                      break
                    fi
                    sleep 4
                  done

                  # k0s applies control-plane:NoSchedule taint even with --enable-worker
                  # Remove it so pods can schedule on the single node
                  kubectl taint node --all node-role.kubernetes.io/control-plane:NoSchedule- 2>/dev/null || true
                  echo "Removed control-plane taint to allow workload scheduling"

                  # ---- Phase 4: Prepare Flux bootstrap ----
                  operation "Preparing namespace and SOPS key (before Flux sync applies SOPS kustomizations)..." "Failed to prepare namespace and SOPS key" "kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -"
                  operation "Creating secret sops-age..." "Failed to create secret sops-age" "kubectl create secret generic sops-age --namespace=flux-system --from-file=age.agekey=$HOME/.config/sops/age/keys.txt --dry-run=client -o yaml | kubectl apply -f -"

                  # ---- Phase 5: Bootstrap Flux via SSH ----
                  # Bootstrap uses SSH (user's key) for git cloning/pushing.
                  # Flux generates its own deploy key; we use --silent to skip
                  # the interactive prompt, then inject the user's key afterward
                  # so the GitRepository sync works without a GitHub deploy key.
                  flux bootstrap git \
                    --url="ssh://git@github.com/soriPhoono/guenivir.git" \
                    --branch="$(git rev-parse --abbrev-ref HEAD)" \
                    --path=k8s/clusters/testing \
                    --private-key-file="$HOME/.ssh/id_ed25519" \
                    --silent \
                    2>&1 || echo "Bootstrap deploy key step may have been skipped (expected with fine-grained PAT)"

                  # Flux generated its own SSH key pair and stored it in the
                  # flux-system secret for ongoing GitRepository reconciliation.
                  # No additional key injection needed.

                  echo "Done!"
                  echo "----------------------------------------"
                  echo ""
                  echo "Cluster kubeconfig merged into ~/.kube/config"
                  echo "Context 'k0s-guenivir-testing' is active."
                  echo ""
                  echo "Try:  kubectl get nodes"
                  echo ""
                  echo "To switch back:"
                  echo "  kubectl config use-context <other-context>"
                  echo ""
                  echo "To tear down:"
                  echo "  docker rm -f $CLUSTER_NAME"
                  echo "  # then restore your previous kubeconfig:"
                  echo "  #   mv ~/.kube/config.bak ~/.kube/config"
                '';
              }
            }/bin/deploy";
          };
          default = deploy;
        };
      };
    };
}

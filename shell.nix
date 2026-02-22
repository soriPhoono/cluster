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
      talosctl

      kubectl
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      # Deploy gemini mcp servers to antigravity if `antigravity` is the current editor
      # Both VS Code and antigravity set TERM_PROGRAM=vscode, but antigravity's GIT_ASKPASS path
      # contains 'antigravity' (e.g. /nix/store/...-antigravity-.../antigravity)
      if [[ "$VSCODE_GIT_ASKPASS_NODE" == *"antigravity"* ]]; then
        echo "Deploying gemini mcp servers to antigravity..."
        # Read the mcpServers json field from .gemini/settings.json and copy it to antigravity's config directory
        # ~/.gemini/antigravity/mcp_config.json
        mkdir -p ~/.gemini/antigravity
        ${pkgs.jq}/bin/jq '{mcpServers: .mcpServers}' ${./.gemini/settings.json} > ~/.gemini/antigravity/mcp_config.json
      fi

      export TF_VAR_proxmox_api_secret="$PROXMOX_API_SECRET"
      export TF_VAR_tailscale_oauth_client_id="$TAILSCALE_OAUTH_CLIENT_ID"
      export TF_VAR_tailscale_oauth_client_secret="$TAILSCALE_OAUTH_CLIENT_SECRET"

      mkdir -p generated
      export TALOSCONFIG="$PWD/generated/talosconfig"
      export KUBECONFIG="$PWD/generated/kubeconfig"
    '';
  }

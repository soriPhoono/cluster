{pkgs, ...}: {
  settings.hooks = {
    # --- Nix Code Support ---
    nil.enable = true;
    statix.enable = true;
    deadnix.enable = true;
    treefmt.enable = true;

    # --- Terraform Support ---
    terraform-format.enable = true;
    tflint.enable = true;
    terrascan = {
      enable = true;
      entry = "${pkgs.terrascan}/bin/terrascan";
      types = ["terraform" "text"];
      args = ["scan"];
    };

    # --- Kubernetes Development Support ---
    kubeconform = {
      enable = true;
      entry = "${pkgs.kubeconform}/bin/kubeconform";
      files = "^k8s/.*\\.yaml$";
      args = ["-ignore-missing-schemas" "-skip" "CustomResourceDefinition" "-kubernetes-version" "1.30.0"];
      excludes = [
        "^k8s/clusters/*/flux-system/.*"
      ];
    };

    # --- GitHub and Git Support ---
    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
      pass_filenames = false;
    };
    actionlint.enable = true;
    action-validator = {
      enable = true;
      name = "action-validator";
      description = "Validate GitHub Action workflows";
      files = "^.github/workflows/";
      entry = let
        script = pkgs.writeShellScript "action-validator-wrapper" ''
          set -e
          for file in "$@"; do
            ${pkgs.action-validator}/bin/action-validator "$file"
          done
        '';
      in "${script}";
    };
  };
}

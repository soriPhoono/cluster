_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    # Terraform
    terraform.enable = true;

    # K8s
    yamlfmt = {
      enable = true;
      excludes = [
        ".sops.yaml"
        "**/*.sops.yaml"
        "**/flux-system/*.yaml"
      ];
    };

    # Docs/Agentics
    mdformat = {
      enable = true;
      excludes = [
        ".agents/**/*.md"
      ];
    };
  };
}

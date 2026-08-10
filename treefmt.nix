_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    yamlfmt = {
      enable = true;
      excludes = [
        ".sops.yaml"
        "**/*.sops.yaml"
        "**/flux-system/*.yaml"
      ];
    };

    mdformat = {
      enable = true;
      excludes = [
        ".agents/**/*.md"
      ];
    };
  };
}

_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    yamlfmt = {
      enable = true;
      includes = ["stacks/**/*.yaml" "stacks/**/*.yml"];
    };

    actionlint.enable = true;

    mdformat.enable = true;
  };
}

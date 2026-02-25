_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    shfmt.enable = true;
    shellcheck.enable = true;

    actionlint.enable = true;

    mdformat.enable = true;
  };
}

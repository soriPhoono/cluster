_: {
  projectRootFile = "flake.nix";
  settings.formatter.yamlfmt.excludes = [".github/workflows/*"];
  settings.formatter.yamllint.excludes = [".github/workflows/*"];

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    shfmt.enable = true;
    shellcheck.enable = true;

    yamlfmt.enable = true;
    yamllint.enable = true;
    actionlint.enable = true;

    mdformat.enable = true;
  };
}

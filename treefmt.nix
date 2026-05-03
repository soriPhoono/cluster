_: {
  settings = {
    excludes = [
      "k3s/clusters/*/flux-system/*.yaml"
    ];
  };

  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    yamlfmt.enable = true;

    mdformat.enable = true;
  };
}

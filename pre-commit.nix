{pkgs, ...}: {
  settings.hooks = {
    nil.enable = true;
    statix.enable = true;
    deadnix.enable = true;

    treefmt.enable = true;

    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
    };

    kubeconform = {
      enable = true;
      name = "kubeconform";
      entry = "${pkgs.kubeconform}/bin/kubeconform";
      files = "^k8s/.*\\.ya?ml$";
      types = ["yaml"];
    };
  };
}

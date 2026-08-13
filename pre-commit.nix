{pkgs, ...}: {
  settings.hooks = {
    nil.enable = true;

    treefmt.enable = true;

    terraform-format.enable = true;
    tflint.enable = true;

    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
      pass_filenames = false;
    };
  };
}

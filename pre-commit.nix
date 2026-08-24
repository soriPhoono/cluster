{pkgs, ...}: {
  settings.hooks = {
    nil.enable = true;

    treefmt.enable = true;

    terraform-format.enable = true;
    tflint.enable = true;

    yamllint = {
      enable = true;
      files = "\\.(yaml|yml)$";
      excludes = [
        "(^|/)\\.sops\\.yaml$"
        "(^|/)secrets\\.enc\\.yaml$"
      ];
      settings.configuration = ''
        extends: default
        rules:
          document-start: disable
          line-length: disable
          truthy: disable
      '';
    };

    kubernetes-validate = {
      enable = true;
      name = "kubernetes-validate";
      entry = "${pkgs.kubernetes-validate}/bin/kubernetes-validate --strict --no-warn -k 1.36.0";
      files = "^k8s/.*\\.(yaml|yml)$";
      pass_filenames = true;
    };

    kube-linter = {
      enable = true;
      name = "kube-linter";
      entry = "${pkgs.kube-linter}/bin/kube-linter lint --config .kube-linter.yaml --format plain";
      files = "^k8s/.*\\.(yaml|yml)$";
      pass_filenames = true;
    };

    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
      pass_filenames = false;
    };
  };
}

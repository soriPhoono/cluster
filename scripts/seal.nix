{pkgs, ...}: {
  type = "app";
  program = "${pkgs.writeShellApplication {
    name = "seal.sh";
    text = ''
      sops --encrypt --in-place ./talos/talosconfig
      sops --encrypt --in-place ./talos/controlplane.yaml
      sops --encrypt --in-place ./talos/worker.yaml
    '';
  }}/bin/seal.sh";
}

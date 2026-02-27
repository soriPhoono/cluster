{pkgs, ...}: {
  type = "app";
  program = "${pkgs.writeShellApplication {
    name = "unseal.sh";
    runtimeInputs = with pkgs; [
      talosctl
      kubectl
      fluxcd
    ];
    text = ''
      sops --decrypt --in-place ./talos/talosconfig
      sops --decrypt --in-place ./talos/controlplane.yaml
      sops --decrypt --in-place ./talos/worker.yaml
    '';
  }}/bin/unseal.sh";
}

{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nil
      alejandra

      age
      agenix
      sops
      ssh-to-age

      talosctl
      kubectl
      kubernetes-helm
      fluxcd

      qemu
      OVMF
      iptables
      bridge-utils
      dnsmasq
    ];

    CONTROL_PLANE_IP = "100.122.30.64";

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      # TODO: Add dynamic generation of devShell GitHub Actions workflow files from ./actions.nix
    '';
  }

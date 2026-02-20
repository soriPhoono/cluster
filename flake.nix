{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    talhelper.url = "github:budimanjojo/talhelper";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }: flake-utils.lib.eachDefaultSystem (system: let 
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells = rec {
      dev = pkgs.mkShell {
        TALOSCONFIG = "clusterconfig/talosconfig";

        packages = with pkgs; [
          sops
          
          (inputs.talhelper.packages.${system}.default)
          talosctl
          kubectl
        ];

        shellHook = let 
          clusterConfig = import ./cluster-config.nix;
          CLUSTER_NAME = clusterConfig.clusterName;
          CONTROL_NODES = clusterConfig.controlNodes;
          WORKER_NODES = clusterConfig.workerNodes;

          CONTROL_PLANE_IP = (builtins.elemAt CONTROL_NODES 0).ipAddress;
        in ''
          if [[ ! -d ./clusterconfig ]]; then
            talhelper genconfig --config-file ${pkgs.writeText "talconfig.yaml" ''
              ---
              clusterName: ${CLUSTER_NAME}
              endpoint: https://${CONTROL_PLANE_IP}:6443
              nodes:
              ${builtins.concatStringsSep "\n"
                (map 
                  (node: ''
                    - hostname: ${node.hostname}
                      controlPlane: true
                      machineSpec:
                        mode: ${node.machine.mode}
                      ipAddress: ${node.ipAddress}
                      installDisk: ${if (node ? "installDisk") then node.installDisk else "/dev/sda"}
                      schematic:
                        customization:
                          systemExtensions:
                            officialExtensions:
                              ${builtins.concatStringsSep "\n"
                                (if (node.extensions ? "official") then
                                  (map (extension: "- ${extension}") node.extensions.official)
                                else [])}
                  '')
                  CONTROL_NODES)}
              ${builtins.concatStringsSep "\n"
                (map
                  (node: ''
                    - hostname: ${node.hostname}
                      ipAddress: ${node.ipAddress}
                      machineSpec:
                        mode: ${node.machine.mode}
                      installDisk: ${if (node ? "installDisk") then node.installDisk else "/dev/sda"}
                      schematic:
                        customization:
                          systemExtensions:
                            officialExtensions:
                              ${builtins.concatStringsSep "\n"
                                (if (node.extensions ? "official") then
                                  (map (extension: "- ${extension}") node.extensions.official)
                                else [])}
                  '')
                  WORKER_NODES)}
            ''}
          fi

          talosctl config endpoint ${CONTROL_PLANE_IP}
          talosctl config node ${CONTROL_PLANE_IP}
        '';
      };
      default = dev;
    };
  });
}

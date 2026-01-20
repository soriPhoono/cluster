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
          CLUSTER_NAME = "adams";

          CONTROL_NODES = [
            {
              hostname = "cluster-manager-1";
              ipAddress = "192.168.1.252";
            }
          ];

          WORKER_NODES = [
            {
              hostname = "cluster-worker-1";
              ipAddress = "192.168.1.253";
            }
          ];
        in ''
          if [[ ! -d ./clusterconfig ]]; then
            talhelper genconfig --config-file ${pkgs.writeText "talconfig.yaml" ''
              ---
              clusterName: ${CLUSTER_NAME}
              endpoint: https://${(builtins.elemAt CONTROL_NODES 0).ipAddress}:6443
              nodes:
              ${builtins.concatStringsSep "\n"
                (map 
                  (node: ''
                    - hostname: ${node.hostname}
                      controlPlane: true
                      ipAddress: ${node.ipAddress}
                      installDisk: ${if (node ? "installDisk") then node.installDisk else "/dev/sda"}
                  '')
                  CONTROL_NODES)}
              ${builtins.concatStringsSep "\n"
                (map
                  (node: ''
                    - hostname: ${node.hostname}
                      ipAddress: ${node.ipAddress}
                      installDisk: ${if (node ? "installDisk") then node.installDisk else "/dev/sda"}
                  '')
                  WORKER_NODES)}
            ''}
          fi
        '';
      };
      default = dev;
    };
  });
}

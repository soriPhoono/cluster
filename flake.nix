{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/x86_64-linux";

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix-shell.url = "github:aciceri/agenix-shell";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
      ];
      systems = with inputs; import systems;
      agenix-shell = {
        secrets = {
          CF_API_TOKEN.file = ./secrets/cloudflare_api_token.age;

          POSTGRES_PASSWORD.file = ./secrets/postgres_password.age;
          MARIADB_PASSWORD.file = ./secrets/mariadb_password.age;
          MONGODB_PASSWORD.file = ./secrets/mongodb_password.age;
          MONGO_EXPRESS_PASSWORD.file = ./secrets/mongo_express_password.age;

          TAILSCALE_AUTH_KEY.file = ./secrets/tailscale_auth_key.age;

          DJANGO_SECRET_KEY.file = ./secrets/funkwhale-django_secret_key.age;
          TYPESENSE_API_KEY.file = ./secrets/typesense-api_key.age;
          FUNKWHALE_DB_PASSWORD.file = ./secrets/funkwhale_db_password.age;

          PTERODACTYL_DB_PASSWORD.file = ./secrets/pterodactyl_db_password.age;

          N8N_DB_PASSWORD.file = ./secrets/n8n_db_password.age;

          AUTHENTIK_DB_PASSWORD.file = ./secrets/authentik_db_password.age;
          AUTHENTIK_SECRET_KEY.file = ./secrets/authentik_secret_key.age;
        };
      };
      perSystem = {
        system,
        pkgs,
        config,
        lib,
        ...
      }:
        with pkgs;
        with lib; rec {
          packages = {
            default = writeShellApplication {
              name = "deploy-script";

              runtimeInputs = with pkgs; [
                docker
              ];

              text = ''
                set -euo pipefail

                if docker plugin ls | grep -q "Loki Logging Driver"; then
                  echo "Loki Logging Driver plugin already installed"
                else
                  echo "Installing Loki Logging Driver plugin"

                  docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
                fi

                docker compose -f ./docker/admin/proxy/docker-compose.yml up -d --wait --remove-orphans

                docker compose -f ./docker/admin/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/admin/backend/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/admin/monitoring/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/admin/automation/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/admin/downloads/docker-compose.yml up -d --wait --remove-orphans

                docker compose -f ./docker/tail/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/tail/pvr/docker-compose.yml up -d --wait --remove-orphans
                docker compose -f ./docker/tail/jukebox/docker-compose.yml up -d --wait --remove-orphans

                # docker compose -f ./docker/public/auth/docker-compose.yml up -d --wait --remove-orphans

                # docker compose -f ./docker/public/cloud/docker-compose.yml up -d --wait --remove-orphans
              '';
            };

            teardown = writeShellApplication {
              name = "teardown-script";

              runtimeInputs = with pkgs; [
                docker
              ];

              text = ''
                set -euo pipefail

                # docker compose -f ./docker/public/cloud/docker-compose.yml down

                # docker compose -f ./docker/public/auth/docker-compose.yml down

                docker compose -f ./docker/tail/jukebox/docker-compose.yml down
                docker compose -f ./docker/tail/pvr/docker-compose.yml down
                docker compose -f ./docker/tail/docker-compose.yml down

                docker compose -f ./docker/admin/downloads/docker-compose.yml down
                docker compose -f ./docker/admin/automation/docker-compose.yml down
                docker compose -f ./docker/admin/monitoring/docker-compose.yml down
                docker compose -f ./docker/admin/backend/docker-compose.yml down
                docker compose -f ./docker/admin/docker-compose.yml down

                docker compose -f ./docker/admin/proxy/docker-compose.yml down
              '';
            };
          };

          devShells.default = mkShell {
            packages = [
              inputs.agenix.packages.${system}.default
            ];

            shellHook = ''
              source ${getExe config.agenix-shell.installationScript}

              ${config.pre-commit.shellHook}
            '';
          };

          treefmt.programs = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;

            yamlfmt.enable = true;
          };

          pre-commit = {
            check.enable = true;
            settings.hooks = {
              nil.enable = true;

              treefmt.enable = true;
            };
          };
        };
    };
}

let
  soriphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgxxFcqHVwYhY0TjbsqByOYpmWXqzlVyGzpKjqS8mO7";

  keys = [soriphoono];
in {
  "secrets/cloudflare_api_token.age".publicKeys = keys;

  "secrets/postgres_password.age".publicKeys = keys;
  "secrets/mariadb_password.age".publicKeys = keys;
  "secrets/mongodb_password.age".publicKeys = keys;
  "secrets/mongo_express_password.age".publicKeys = keys;

  "secrets/tailscale_auth_key.age".publicKeys = keys;

  "secrets/funkwhale_db_password.age".publicKeys = keys;
  "secrets/funkwhale-django_secret_key.age".publicKeys = keys;
  "secrets/typesense-api_key.age".publicKeys = keys;

  "secrets/pterodactyl_db_password.age".publicKeys = keys;

  "secrets/n8n_db_password.age".publicKeys = keys;

  "secrets/authentik_db_password.age".publicKeys = keys;
  "secrets/authentik_secret_key.age".publicKeys = keys;
}

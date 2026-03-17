#!/bin/bash
# =============================================================================
# n8n Database Migration Script
# =============================================================================
# Provisions the n8n database, user, and permissions on the shared PostgreSQL.
# Runs as an init container before n8n starts. Idempotent — safe to re-run.
#
# Required environment:
#   PGHOST, PGPORT        — shared postgres connection
#   PGPASSWORD             — root password (from /run/secrets/postgres_root_password)
#   N8N_DB_USER            — user to create for n8n
#   N8N_DB_PASSWORD        — password for the n8n user (from /run/secrets/n8n_db_password)
#   N8N_DB_NAME            — database to create for n8n
# =============================================================================
set -euo pipefail

# Read secrets from files if provided as _FILE variants
if [ -f "${PGPASSWORD_FILE:-}" ]; then
  PGPASSWORD="$(cat "$PGPASSWORD_FILE")"
  export PGPASSWORD
fi

if [ -f "${N8N_DB_PASSWORD_FILE:-}" ]; then
  N8N_DB_PASSWORD="$(cat "$N8N_DB_PASSWORD_FILE")"
fi

# Defaults
: "${PGHOST:=postgres}"
: "${PGPORT:=5432}"
: "${N8N_DB_USER:=n8n}"
: "${N8N_DB_NAME:=n8n}"

echo "==> Waiting for PostgreSQL at ${PGHOST}:${PGPORT}..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U postgres -q; do
  sleep 1
done
echo "==> PostgreSQL is ready."

echo "==> Provisioning database '${N8N_DB_NAME}' and user '${N8N_DB_USER}'..."
psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U postgres <<-EOSQL
  -- Create user if not exists
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${N8N_DB_USER}') THEN
      CREATE USER ${N8N_DB_USER} WITH PASSWORD '${N8N_DB_PASSWORD}';
      RAISE NOTICE 'User ${N8N_DB_USER} created.';
    ELSE
      -- Update password in case it changed
      ALTER USER ${N8N_DB_USER} WITH PASSWORD '${N8N_DB_PASSWORD}';
      RAISE NOTICE 'User ${N8N_DB_USER} already exists, password updated.';
    END IF;
  END
  \$\$;

  -- Create database if not exists
  SELECT 'CREATE DATABASE ${N8N_DB_NAME} OWNER ${N8N_DB_USER}'
  WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${N8N_DB_NAME}')\gexec

  -- Grant privileges
  GRANT ALL PRIVILEGES ON DATABASE ${N8N_DB_NAME} TO ${N8N_DB_USER};
EOSQL

# Grant schema permissions (must connect to the target database)
psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U postgres -d "$N8N_DB_NAME" <<-EOSQL
  GRANT CREATE ON SCHEMA public TO ${N8N_DB_USER};
  GRANT USAGE ON SCHEMA public TO ${N8N_DB_USER};
EOSQL

echo "==> Migration complete. Database '${N8N_DB_NAME}' is ready for user '${N8N_DB_USER}'."

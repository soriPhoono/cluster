#!/usr/bin/env bash
set -e

DB_HOST=$DB_POSTGRESDB_HOST
DB_USER=postgres
DB_PASS=$POSTGRES_PASSWORD
DB_NAME=$DB_POSTGRESDB_DATABASE
DB_OWNER=$DB_POSTGRESDB_USER
DB_OWNER_PASS=$DB_POSTGRESDB_PASSWORD

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL at $DB_HOST to become available..."
until PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 2
done
>&2 echo "Postgres is up and running."

# Create user with password
>&2 echo "Checking if user $DB_OWNER exists..."
USER_EXISTS=$(PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d postgres \
    -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_OWNER'")
if [ "$USER_EXISTS" = '1' ]; then
    >&2 echo "User $DB_OWNER already exists. Skipping creation."
else
    >&2 echo "Creating database owner user $DB_OWNER..."
    PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d postgres \
        -c "CREATE USER $DB_OWNER WITH PASSWORD '$DB_OWNER_PASS';"
    >&2 echo "User $DB_OWNER created successfully."
fi

# Attempt to create the application database if it doesn't exist
>&2 echo "Checking if database $DB_NAME exists..."
DB_EXISTS=$(PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")

if [ "$DB_EXISTS" = '1' ]; then
    >&2 echo "Database $DB_NAME already exists. Skipping creation."
else    
    # Create database
    >&2 echo "Database $DB_NAME does not exist. Creating it now..."
    PGPASSWORD=$DB_PASS psql -h "$DB_HOST" -U "$DB_USER" -d postgres \
        -c "CREATE DATABASE $DB_NAME OWNER $DB_OWNER;"
    >&2 echo "Database $DB_NAME created successfully."
fi

# Pass control back to the main service command
exec "$@"
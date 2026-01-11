#!/usr/bin/env bash
set -e

# These variables should be passed from your docker-compose.yml environment
# e.g. MARIADB_ROOT_PASSWORD, FUNKWHALE_DB_PASSWORD
DB_HOST=mariadb
DB_ROOT_USER=root
DB_ROOT_PASS=$MARIADB_ROOT_PASSWORD
DB_NAME=panel
DB_USER=pterodactyl
DB_USER_PASS=$PTERODACTYL_DB_PASSWORD

# --- Helper function to execute SQL commands ---
# We use the root user for administrative tasks (creating users and databases)
# Note: The '-N' flag suppresses column headers, and '-s' makes the output silent (less verbose)
# which is useful for capturing a single value from a query.
function mysql_exec {
    mariadb -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -N -s -e "$1"
}

# --- Wait for MariaDB to be ready ---
echo "Waiting for MariaDB at $DB_HOST to become available..."
until mariadb -h "$DB_HOST" -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e 'SELECT 1' &>/dev/null; do
  >&2 echo "MariaDB is unavailable - sleeping"
  sleep 2
done
>&2 echo "MariaDB is up and running."


# --- Check if the database exists ---
>&2 echo "Checking if database '$DB_NAME' exists..."
# Query the information_schema to see if the database is listed
DB_EXISTS=$(mysql_exec "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = '$DB_NAME'")

if [ "$DB_EXISTS" = "$DB_NAME" ]; then
    >&2 echo "Database '$DB_NAME' already exists. Skipping creation."
else
    # --- Database does not exist, so create it ---
    >&2 echo "Database '$DB_NAME' does not exist. Creating it now..."
    mysql_exec "CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    >&2 echo "Database '$DB_NAME' created successfully."
fi


# --- Check if the user exists ---
>&2 echo "Checking if user '$DB_USER' exists..."
# Query the main mysql system database to see if the user is listed
USER_EXISTS=$(mysql_exec "SELECT 1 FROM mysql.user WHERE user = '$DB_USER'")

if [ "$USER_EXISTS" = '1' ]; then
    >&2 echo "User '$DB_USER' already exists. Skipping creation and permission grant."
else
    # --- User does not exist, so create it and grant privileges ---
    >&2 echo "Creating database user '$DB_USER'..."
    # Note: We create the user and grant privileges on the new database in one go.
    # The '%' host means the user can connect from any IP address (e.g., from other containers).
    mysql_exec "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_USER_PASS';"
    >&2 echo "User '$DB_USER' created successfully."

    >&2 echo "Granting privileges to user '$DB_USER' on database '$DB_NAME'..."
    mysql_exec "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';"
    >&2 echo "Privileges granted successfully."
fi

# --- Pass control back to the main service command ---
exec "$@"
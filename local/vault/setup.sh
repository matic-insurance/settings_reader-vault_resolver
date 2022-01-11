#!/bin/sh
set -e

message() {
  TEXT=$1
  echo "-----------------------------"
  echo "${TEXT}"
  echo "-----------------------------"
}

message "Setting up Vault"
vault status

message "Setting up static secret"
vault kv put secret/preconfigured foo=a bar=b

message "Static secret value"
vault kv get secret/preconfigured

message "Setting up dynamic db secret"
vault secrets enable database

message "Configuring database connection"
vault write database/config/app_db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="app-user" \
    connection_url="postgresql://{{username}}:{{password}}@db:5432/app_db?sslmode=disable" \
    username="vault_root" \
    password="root_password"

message "Configuring database role"
vault write database/roles/app-user \
    db_name=app_db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1m" \
    max_ttl="1h"

message "Verifying database role"
vault read database/creds/app-user

message "Vault configured"

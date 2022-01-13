#!/bin/sh
set -e

message() {
  TEXT=$1
  echo "-----------------------------"
  echo "${TEXT}"
  echo "-----------------------------"
}

vault() {
  METHOD=$1
  PATH=$2
  DATA=$3
  /usr/bin/curl \
      -s \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --header "Content-Type: application/json" \
      --request ${METHOD} \
      --data "${DATA}" \
      "${VAULT_ADDR}/${PATH}"
}

message "Setting up Vault"
#vault status

message "Setting up static secret"
vault POST "v1/secret/data/pre-configured" '{"data": {"foo": "a", "bar": "b"}}'

message "Static secret value"
vault GET "v1/secret/data/pre-configured" ''

message "Setting up dynamic db secret"
vault POST "v1/sys/mounts/database" '{"type": "database"}'

message "Configuring database connection"
vault POST "v1/database/config/app_db" \
    '{
       "plugin_name": "postgresql-database-plugin",
       "allowed_roles": "app-user",
       "connection_url": "postgresql://{{username}}:{{password}}@db:5432/app_db?sslmode=disable",
       "username": "vault_root",
       "password": "root_password"
     }'

message "Configuring database role"
vault POST "v1/database/roles/app-user" \
    '{
       "db_name": "app_db",
       "creation_statements": [
         "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''",
         "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\""
       ],
       "default_ttl": "1m",
       "max_ttl": "1h"
     }'

message "Verifying database role"
vault GET "v1/database/creds/app-user"

message "Vault configured"

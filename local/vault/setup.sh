#!/bin/sh
set -e

VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
DATABASE_ADDR=${DATABASE_ADDR:-"db"}

message() {
  TEXT=$1
  echo "-----------------------------"
  echo "${TEXT}"
  echo "-----------------------------"
}

call_vault() {
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
echo "Home Folder: $(pwd)"
sleep 5

message "Setting up static secret"
call_vault POST "v1/secret/data/pre-configured" '{"data": {"foo": "a", "bar": "b"}}'
call_vault POST "v1/secret/data/deep/secret" '{"data": {"foo": "a", "bar": "b"}}'
call_vault POST "v1/secret/data/unreachable/secret" '{"data": {"foo": "a", "bar": "b"}}'

message "Static secret value"
call_vault GET "v1/secret/data/pre-configured" ''

message "Setting up aws secret engine"
call_vault POST "v1/sys/mounts/aws" \
    '{
        "type": "aws"
    }'
call_vault POST "v1/aws/config/root" \
    '{
       "access_key": "root",
       "secret_key": "secret",
       "iam_endpoint": "http://aws:4566",
       "sts_endpoint": "http://aws:4566"
     }'

call_vault POST "v1/aws/config/lease" '{"lease": "1m", "lease_max": "45m"}'
call_vault POST "v1/aws/roles/app-user" '{"credential_type": "iam_user", "policy_arns": ["arn:aws:iam::000000000000:policy/app-access"]}'
call_vault POST "v1/aws/roles/app-role" \
    '{
        "credential_type": "assumed_role",
        "role_arns": ["arn:aws:iam::000000000000:role/app-role"],
        "default_sts_ttl": "15m",
        "max_sts_ttl": "45m"
    }'
call_vault POST "v1/aws/static-roles/app-static-user" '{"username": "app-static-user", "rotation_period": "5m"}'

message "Verifying aws role"
call_vault GET "v1/aws/creds/app-user" ''
call_vault GET "v1/aws/creds/app-role" ''
call_vault GET "v1/aws/static-creds/app-static-user" ''

message "Setting up dynamic db secret"
call_vault POST "v1/sys/mounts/database" '{"type": "database"}'

message "Configuring database connection"
call_vault POST "v1/database/config/app_db" \
    "{
       \"plugin_name\": \"postgresql-database-plugin\",
       \"allowed_roles\": \"app-user\",
       \"connection_url\": \"postgresql://{{username}}:{{password}}@${DATABASE_ADDR}:5432/app_db?sslmode=disable\",
       \"username\": \"vault_root\",
       \"password\": \"root_password\"
     }"

message "Configuring database role"
call_vault POST "v1/database/roles/app-user" \
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
call_vault GET "v1/database/creds/app-user"

message "Setting up app policy"
call_vault POST "v1/sys/policies/acl/app" \
    '{
       "policy": "# ------------------------------------------------\n# Static secrets\n# ------------------------------------------------\n# Allow creation of any secrets for test purposes\npath \"secret/data/test/*\" {\n  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]\n}\n\npath \"secret/metadata/test/*\" {\n  capabilities = [\"list\"]\n}\n\n#Access to preconfigured secrets\npath \"secret/data/pre-configured\" {\n  capabilities = [\"read\"]\n}\n\npath \"secret/metadata/pre-configured\" {\n  capabilities = [\"list\"]\n}\n\npath \"secret/data/deep/*\" {\n  capabilities = [\"read\"]\n}\n\npath \"secret/metadata/deep/*\" {\n  capabilities = [\"list\"]\n}\n\n# ------------------------------------------------\n# Database secrets\n# ------------------------------------------------\npath \"database/creds/app-user\" {\n  capabilities = [\"read\"]\n}\n\n#allow reading missing creds for tests\npath \"database/creds/unknown-db\" {\n  capabilities = [\"read\"]\n}\n\n#Deep path to allow renewal only for allowed credentials\npath \"sys/renew/database/creds/app-user/*\" {\n  capabilities = [\"create\", \"update\"]\n}\n\n# ------------------------------------------------\n# AWS secrets\n# ------------------------------------------------\npath \"aws/creds/app-user\" {\n  capabilities = [\"read\"]\n}\n\npath \"aws/creds/app-role\" {\n  capabilities = [\"read\"]\n}\n\npath \"aws/static-creds/app-static-user\" {\n  capabilities = [\"read\"]\n}\n\npath \"aws/creds/app-missing\" {\n  capabilities = [\"read\"]\n}\n\npath \"sys/renew/aws/creds/app-user/*\" {\n  capabilities = [\"create\", \"update\"]\n}\n"
     }'

message "Verifying app policy"
call_vault GET "v1/sys/policy/app" ''

message "Vault configured"

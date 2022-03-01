# Allow creation of any secrets for test purposes
path "secret/data/test/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/test/*" {
  capabilities = ["list"]
}

#Access to preconfigured secrets
path "secret/data/pre-configured" {
  capabilities = ["read"]
}

path "secret/metadata/pre-configured" {
  capabilities = ["list"]
}

path "secret/data/deep/*" {
  capabilities = ["read"]
}

path "secret/metadata/deep/*" {
  capabilities = ["list"]
}

# Access to dynamic credentials
path "database/creds/app-user" {
  capabilities = ["read"]
}

#allow reading missing creds for tests
path "database/creds/unknown-db" {
  capabilities = ["read"]
}

#Deep path to allow renewal only for allowed credentials
path "sys/renew/database/creds/app-user/*" {
  capabilities = ["create", "update"]
}

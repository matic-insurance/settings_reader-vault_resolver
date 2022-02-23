# SettingsReader::VaultResolver

![Build Status](https://github.com/matic-insurance/settings_reader-vault_resolver/workflows/ci/badge.svg?branch=main)
[![Test Coverage](https://codecov.io/gh/matic-insurance/settings_reader-vault_resolver/branch/main/graph/badge.svg?token=dGVDB9judr)](https://codecov.io/gh/matic-insurance/settings_reader-vault_resolver)

Settings Reader plugin to resolve values using in Hashicorp Vault

This gem works as a plugin for [Settings Reader](https://github.com/matic-insurance/consul_application_settings)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'settings_reader'
gem 'settings_reader-vault_resolver'
```

## Usage

### Initialization

At the load of application when initializing `settings_reader`:
```ruby
#Init vault
Vault.address = 'http://127.0.0.1:8200'
Vault.token = 'MY_SUPER_SECRET_TOKEN'

#Load Settings Reader and configure resolver
AppSettings = SettingsReader.load do |config|
  # ... Other configurations
  
  # Add vault resolver as one of resolvers
  config.resolvers << SettingsReader::VaultResolver.resolver
end
```

### Usage
If one of the values provided will begin with `vault://` scheme - 
`VaultResolver` gem will kick in and will try to resolve path in Vault

Assuming your settings has following structure:
```yaml
app:
  name: 'MyCoolApp'
  hostname: 'http://localhost:3001'
  static_secret: 'vault://secret/apps/my_cool_app#app_secret'
  dynamic_secret: 'vault://database/creds/app-db#username'
```

When requesting `app/secret` from `SettingsReader` it will resolve in Vault as:

```ruby
secret = AppSettings.get('app/static_secret') 
# Gem will read `vault://secret/app#secret` from YAML
# Gem will resolve value in Vault using Vault.kv('secret').read('apps/my_cool_app')
# Gem will return `app_secret` attribute from the secret resolved above

db_user = AppSettings.get('app/dynamic_secret')
# Gem will request dynamic credentials from `vault://database/creds/app-db` and cache them
# Gem will renew lease on retrieved credentials 3 minutes prior lease expiration from vault
# Gem will return `username` attribute from dynamic secret
```

## Development

1. Run `bin/setup` to install dependencies
2. Run `docker-compose up` to spin up dependencies (Vault)
3. Run tests `rspec`
4. Add new test
5. Add new code
6. Go to step 3
7. Create PR

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/matic-insurance/settings_reader-vault_resolver. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/matic-insurance/settings_reader-vault_resolver/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SettingsReader::VaultResolver project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/matic-insurance/settings_reader-vault_resolver/blob/master/CODE_OF_CONDUCT.md).

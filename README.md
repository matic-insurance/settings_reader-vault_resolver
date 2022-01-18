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

#Init Settings Reader
SettingsReader.configure do |config|
  config.settings_providers = [
    SettingsReader::Providers::Yaml,
  ]

  config.value_resolvers = [
    SettingsReader::Resolvers::Vault,
    SettingsReader::Resolvers::Env,
  ]
end

#Load Settings
APP_SETTINGS = SettingsReader.load
```

### Usage
If one of the values provided will begin with `vault://` scheme - 
`VaultResolver` gem will kick in and will try to resolve path in Vault

Assuming your settings has following structure:
```yaml
app:
  name: 'MyCoolApp'
  hostname: 'http://localhost:3001'
  secret: 'vault://secret/apps/my_cool_app#app_secret'
```

When requesting `app/secret` from `SettingsReader` it will resolve in Vault as:

```ruby
secret = APP_SETTINGS.get('app/secret') 
# Gem will read `vault://secret/app#secret` from YAML
# Gem will resolve value in Vault using Vault.kv('secret').read('apps/my_cool_app')
# Gem will return `app_secret` attribute from the secret resolved above
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

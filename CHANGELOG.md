## [Unreleased]

## [0.4.2]
### Fixes
- Fix lost secret data after lease renewal
- Fix exception when getting value from secret with nil data

## [0.4.1]
### Changes
- Broader entry secret data access to allow retrieval of secret attributes

### Fixes
- Fix exception when retrieving authenticating via k8s endpoint

### New features
- Retry secret retrieval and renewal
- Capture more vault exceptions including connectivity errors
- Introduce vault engine adapter concept
- Separate kv, database, and auth engine logic

## [0.4.0]
### Breaking changes
- Reworked authentication helpers interface

### New features
- Retry secret retrieval and renewal
- Capture more vault exceptions including connectivity errors
- Introduce vault engine adapter concept
- Separate kv, database, and auth engine logic 

## [0.3.0]
### Breaking changes
- Require configuration before use

### New features
- Gem configurations
- Require configuration before use
- Report renew errors via configuration listeners

### Fixes
- Cleanup logging

## [0.2.4]
### Fixes
- Fix refresher task logging

## [0.2.3]
### Fixes
- Fix logging setup when gem loaded before rails

## [0.2.2]
### New features
- Add logging to gem

## [0.2.1]
### Fixes
- Use default k8s auth route without namespace 

## [0.2.0]
### New features
- Better integration with parent gem
- Support of k8s authentication method
- Additional tests and fixes related to Vault permissions

## [0.1.1]
### Fixes
- Fix CI release
- Add changelog

## [0.1.0]
### New features
- Retrieving static and dynamic secrets from vault
- Secrets caching
- Automatic secrets lease renewal

[Unreleased]: https://github.com/matic-insurance/settings_reader-vault_resolver/compare/0.4.2...HEAD
[0.4.2]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.4.2
[0.4.1]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.4.1
[0.4.0]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.4.0
[0.3.0]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.3.0
[0.2.4]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.2.4
[0.2.3]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.2.3
[0.2.2]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.2.2
[0.2.1]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.2.1
[0.2.0]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.2.0
[0.1.1]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.1.1
[0.1.0]: https://github.com/matic-insurance/settings_reader-vault_resolver/commits/0.1.0

